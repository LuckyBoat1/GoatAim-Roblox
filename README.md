# GoatAim Project
Synced with [Rojo](https://github.com/rojo-rbx/rojo) 7.5.1.

## Structure
ReplicatedStorage
	Shared/ (shared ModuleScripts)
		SkinConfig.lua (single canonical skin + ADS config module)
		Hello.luau (example)
	RemoteEvents/ (only RemoteEvent / Bindable containers – keep logic in Shared or Server)

ServerScriptService
	Server/ (all server scripts & server-only modules)
		QuestCatalog.lua (quest registry) – duplicates removed

StarterPlayer
	StarterPlayerScripts/Client/ (client LocalScripts & client-only modules)
		ADSClient.client.luau (Aim Down Sights handler)

Removed duplicates/stubs: old SkinConfig duplicates and misspelled QuestCatalgo.

## Commands
Build place file:
```powershell
rojo build -o Game.rbxlx
```
Live sync (from workspace root):
```powershell
rojo serve
```

## Conventions
1. One ModuleScript per logical system (SkinConfig, QuestCatalog, etc.).
2. No duplicate filenames providing same API.
3. RemoteEvents folder contains only communication primitives, not logic copies.
4. Client requires use `ReplicatedStorage.Shared` modules.
5. Add new shared modules into `src/shared` – no need to edit `default.project.json`.

## Next Ideas
- Add tests (e.g. using TestService) for SkinConfig.
- Introduce linting (Selene) & formatting (StyLua) once stable.
- Document quest definitions JSON/source.

## Reference
Rojo docs: https://rojo.space/docs