import httpx
import pytest

pytestmark = pytest.mark.asyncio


async def test_create_issue_with_media_urls(client: httpx.AsyncClient, auth_headers: dict[str, str]):
    """Creating an issue with a list of media_urls persists and returns media_urls in IssueOut."""
    media_list = [
        "https://res.cloudinary.com/demo/image/upload/img1.jpg",
        "https://res.cloudinary.com/demo/image/upload/img2.jpg",
    ]
    response = await client.post(
        "/api/v1/issues",
        json={
            "title": "Severe Water Logging",
            "description": "Entire street submerged after rain",
            "category": "water",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
            "media_urls": media_list,
        },
        headers=auth_headers,
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["media_urls"] == media_list
    assert data["media_url"] == media_list[0]
    assert data["video_url"] is None
    assert data["reporter_id"] is not None

    # Fetch single issue
    get_res = await client.get(f"/api/v1/issues/{data['id']}", headers=auth_headers)
    assert get_res.status_code == 200
    assert get_res.json()["media_urls"] == media_list


async def test_create_issue_with_media_url_and_video_url(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
):
    """Creating an issue with media_url and video_url populates media_urls list and single url fields."""
    response = await client.post(
        "/api/v1/issues",
        json={
            "title": "Broken Overpass Barrier",
            "description": "Safety hazard on highway flyover",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
            "media_url": "https://res.cloudinary.com/demo/image/upload/barrier.jpg",
            "video_url": "https://res.cloudinary.com/demo/video/upload/dashcam.mp4",
        },
        headers=auth_headers,
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["media_url"] == "https://res.cloudinary.com/demo/image/upload/barrier.jpg"
    assert data["video_url"] == "https://res.cloudinary.com/demo/video/upload/dashcam.mp4"
    assert "https://res.cloudinary.com/demo/image/upload/barrier.jpg" in data["media_urls"]
    assert "https://res.cloudinary.com/demo/video/upload/dashcam.mp4" in data["media_urls"]


async def test_reporter_id_visibility_public_vs_anonymous(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
):
    """Public issues show reporter_id to everyone; anonymous issues mask reporter_id to non-authors."""
    # Create public issue
    pub_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Public Park Bench Damaged",
            "description": "Bench broken near jogging track",
            "category": "parks",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    assert pub_res.status_code == 201
    pub_data = pub_res.json()
    pub_id = pub_data["id"]
    author_id = pub_data["reporter_id"]
    assert author_id is not None

    # Create anonymous issue
    anon_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Anonymous Bribery Complaint",
            "description": "Demanded bribe for permit",
            "category": "other",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": True,
        },
        headers=auth_headers,
    )
    assert anon_res.status_code == 201
    anon_id = anon_res.json()["id"]

    # Author fetches both issues
    author_pub = await client.get(f"/api/v1/issues/{pub_id}", headers=auth_headers)
    assert author_pub.json()["reporter_id"] == author_id

    author_anon = await client.get(f"/api/v1/issues/{anon_id}", headers=auth_headers)
    assert author_anon.json()["reporter_id"] == author_id

    # Another user fetches both issues
    other_headers = await create_user_headers("+919876540003")
    other_pub = await client.get(f"/api/v1/issues/{pub_id}", headers=other_headers)
    assert other_pub.json()["reporter_id"] == author_id

    other_anon = await client.get(f"/api/v1/issues/{anon_id}", headers=other_headers)
    assert other_anon.json()["reporter_id"] is None  # Masked for privacy!

    # Unauthenticated visitor fetches both issues
    unauth_pub = await client.get(f"/api/v1/issues/{pub_id}")
    assert unauth_pub.json()["reporter_id"] == author_id

    unauth_anon = await client.get(f"/api/v1/issues/{anon_id}")
    assert unauth_anon.json()["reporter_id"] is None  # Masked for privacy!


async def test_upvote_post_and_delete_toggle_cycle(
    client: httpx.AsyncClient, auth_headers: dict[str, str], create_user_headers
):
    """POST /issues/{id}/upvote and DELETE /issues/{id}/upvote accurately mutate upvotes_count and has_upvoted."""
    # Create an issue
    issue_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Clogged Storm Drain",
            "description": "Drain overflowing with debris",
            "category": "drainage",
            "latitude": 19.1136,
            "longitude": 72.8697,
            "is_anonymous": False,
        },
        headers=auth_headers,
    )
    assert issue_res.status_code == 201
    issue_id = issue_res.json()["id"]
    assert issue_res.json()["upvotes_count"] == 0

    voter_1 = await create_user_headers("+919876540004")
    voter_2 = await create_user_headers("+919876540005")

    # 1. Voter 1 upvotes
    upvote1_resp = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_1,
    )
    assert upvote1_resp.status_code == 200
    u1_data = upvote1_resp.json()
    assert u1_data["has_upvoted"] is True
    assert u1_data["upvotes_count"] == 1

    # 2. Voter 2 upvotes
    upvote2_resp = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=voter_2,
    )
    assert upvote2_resp.status_code == 200
    u2_data = upvote2_resp.json()
    assert u2_data["has_upvoted"] is True
    assert u2_data["upvotes_count"] == 2

    # 3. Voter 1 un-upvotes via DELETE
    unvote1_resp = await client.delete(
        f"/api/v1/issues/{issue_id}/upvote",
        headers=voter_1,
    )
    assert unvote1_resp.status_code == 200
    un1_data = unvote1_resp.json()
    assert un1_data["has_upvoted"] is False
    assert un1_data["upvotes_count"] == 1

    # 4. Voter 2 checks issue state -> still has_upvoted=True
    get_voter2 = await client.get(f"/api/v1/issues/{issue_id}", headers=voter_2)
    assert get_voter2.status_code == 200
    assert get_voter2.json()["has_upvoted"] is True
    assert get_voter2.json()["upvotes_count"] == 1

    # 5. Voter 2 un-upvotes via DELETE
    unvote2_resp = await client.delete(
        f"/api/v1/issues/{issue_id}/upvote",
        headers=voter_2,
    )
    assert unvote2_resp.status_code == 200
    un2_data = unvote2_resp.json()
    assert un2_data["has_upvoted"] is False
    assert un2_data["upvotes_count"] == 0

    # 6. Trying to un-upvote again returns 400 not_upvoted
    unvote_again = await client.delete(
        f"/api/v1/issues/{issue_id}/upvote",
        headers=voter_2,
    )
    assert unvote_again.status_code == 400
    assert unvote_again.json().get("code") == "not_upvoted" or unvote_again.json().get("detail") == "not_upvoted"


async def test_guest_upvote_and_unvote_restrictions(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
):
    """Guest users cannot upvote or remove upvotes on issues."""
    issue_res = await client.post(
        "/api/v1/issues",
        json={
            "title": "Damaged Road Sign",
            "description": "Sign fallen down",
            "category": "road",
            "latitude": 19.1136,
            "longitude": 72.8697,
        },
        headers=auth_headers,
    )
    issue_id = issue_res.json()["id"]

    guest_auth = await client.post("/api/v1/auth/guest")
    guest_token = guest_auth.json()["access_token"]
    guest_headers = {"Authorization": f"Bearer {guest_token}"}

    # Guest POST upvote -> 403
    post_resp = await client.post(
        f"/api/v1/issues/{issue_id}/upvote",
        json={"latitude": 19.1136, "longitude": 72.8697},
        headers=guest_headers,
    )
    assert post_resp.status_code == 403
    assert post_resp.json().get("code") == "guest_restricted"

    # Guest DELETE upvote -> 403
    del_resp = await client.delete(
        f"/api/v1/issues/{issue_id}/upvote",
        headers=guest_headers,
    )
    assert del_resp.status_code == 403
    assert del_resp.json().get("code") == "guest_restricted"
