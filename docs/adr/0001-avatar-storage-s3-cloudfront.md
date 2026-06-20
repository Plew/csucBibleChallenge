# Serve user avatars from S3 behind CloudFront

User avatars are uploaded via Active Storage and today live on the production server's local disk (`storage/`), served *through* the Rails app. To get fast, edge-cached delivery and offload image serving from the app server, we will move avatar storage to a public-read S3 bucket fronted by a CloudFront distribution, and serve avatars via stable public CDN URLs.

## Status

proposed

## Considered Options

- **Keep local disk (status quo).** Simple, no AWS dependency, but every avatar request hits the Rails app and is not edge-cached; uploads are tied to the box.
- **S3 only (no CDN).** Durable off-box storage, but still no edge caching and URLs are either signed/expiring or hit S3 directly.
- **S3 + CloudFront, public-read (chosen).** Durable storage plus edge caching and stable public URLs. Avatars are non-sensitive (already shown publicly on leaderboards), so public-read is acceptable and avoids signed-URL complexity.

## Consequences

- Introduces AWS lock-in (S3 + CloudFront) and requires AWS credentials in the Kamal deploy environment.
- Existing avatar files in `storage/` must be migrated to S3 as part of the cutover.
- `avatar_image_tag` / `AvatarComponent` URL generation must resolve to the CloudFront host (e.g. via `asset_host` / Active Storage public URLs) rather than the Rails disk service.
- This is tracked as a separate effort from the challenge management-hub redesign — different risk profile and provisioning needs; it must not block the UI work.
