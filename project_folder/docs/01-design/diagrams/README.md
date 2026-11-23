# Architecture diagrams

`architecture.md` contains three Mermaid diagrams that render directly on GitHub:

1. **System overview** - staff -> CLI -> private storage; auditor -> expiring link -> single blob.
2. **Data flow** - upload and share flows with the audit-log write point marked.
3. **Trust boundary** - what is private, what is a temporary capability, what is public.

GitHub renders Mermaid in `.md` files automatically. To export a PNG/SVG, paste the
source into <https://mermaid.live> and download the image here, then link it from
`docs/02-architecture/`.

The system overview is also embedded in `docs/02-architecture/system-overview.md` so
readers do not have to leave the architecture section.
