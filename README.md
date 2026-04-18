# Hackathon-TBS

Senior Companion hackathon workspace.

## Context Pack
- `Context/00_readme_context_pack.md`
- `Context/01_theme_hackathon.md`
- `Context/02_research_context_summary.md`
- `Context/03_cahier_des_charges_aligne.md`
- `Context/04_business_model_canvas_aligne.md`
- `Context/05_technical_document.md`
- `Context/06_ui_ux_requirements.md`
- `Context/07_ai_coding_context.md`

## Execution Pack
- `Execution/00_delivery_overview.md`
- `Execution/01_mvp_user_stories.md`
- `Execution/02_api_contract_v1.yaml`
- `Execution/03_event_rules_and_status_model.md`
- `Execution/04_ui_ux_screen_map.md`

## Frontend (React MVP)
- `Frontend/src/` - Complete React app with all 5 key screens
- Ready to run: `npm install && npm run dev`
- Fully styled with Tailwind CSS, mobile-first
- TypeScript, interactive demos, role-switching

## Quick Start For Team
1. **Run frontend immediately**: `cd Frontend && npm install && npm run dev`
2. Align on MVP scope in `Execution/00_delivery_overview.md`.
3. Implement P0 stories from `Execution/01_mvp_user_stories.md`.
4. Build backend endpoints from `Execution/02_api_contract_v1.yaml`.
5. Implement status engine from `Execution/03_event_rules_and_status_model.md`.
6. Connect frontend to backend (replace mock context in `Frontend/src/context/AppContext.tsx`).