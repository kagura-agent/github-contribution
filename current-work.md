# Current Work

## Issue
- **Repo**: modelcontextprotocol/inspector
- **Issue**: #1462
- **Title**: ResourceControls: sections scroll prematurely (equal height-division) + accordion chevrons point up/down instead of right/down
- **URL**: https://github.com/modelcontextprotocol/inspector/issues/1462

## Two Problems
1. **Premature scrolling**: `panelMaxHeight` divides available height equally among open sections (`/n`), causing scrolling in populated sections while empty sections waste space
2. **Wrong chevrons**: Default Mantine chevrons point up/down, should point right/down

## Key Files
- `clients/web/src/components/groups/ResourceControls/ResourceControls.tsx` (main fix)
- `ResourceLink.tsx` (existing chevron pattern to follow)
- `ResourceControls.test.tsx` / `.stories.tsx` (tests/stories to update)
- `ServerSettingsForm/ServerSettingsForm.tsx` (verify if chevron change is app-wide)

## Acceptance Criteria
- Content-aware height allocation (no premature scrollbar)
- Chevrons: right=closed, down=open (using RiArrowRightSLine/RiArrowDownSLine)
- Tests + stories updated
- `npm run validate` + `npm run test:storybook` pass
