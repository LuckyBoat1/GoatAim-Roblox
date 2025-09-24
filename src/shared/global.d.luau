--!strict
-- Global type declarations for _G to reduce editor errors.

type WeaponStats = { bulletsShot: number, itemsShot: number, timeRolled: number }
type PlayerData = {
    money: number,
    trumpCoin: number,
    rank: number,
    skins: { [string]: boolean },
    weaponStats: { [string]: WeaponStats },
    boxes: { [string]: number },
    runHits: number?,
}

type BoxOpenResult = {
    ok: boolean,
    miss: boolean?,
    skinId: string?,
    rarity: string?,
    dupe: boolean?,
    err: string?,
}

type GameGlobals = {
    notify: (player: Player?, text: string) -> (),
    updateLeaderboardGui: (data: any) -> (),
    executeTrade: (trade: any) -> (),

    getData: (plr: Player) -> PlayerData,
    getDataSnapshot: (plr: Player) -> PlayerData,
    addMoney: (plr: Player, delta: number) -> (),
    addTrumpCoins: (plr: Player, delta: number) -> (),
    setMoney: (plr: Player, value: number) -> (),
    setCoins: (plr: Player, value: number) -> (),
    hasSkin: (plr: Player, skinId: string) -> boolean,
    grantSkin: (plr: Player, skinId: string) -> (),
    markWeaponSpawned: (plr: Player, weaponName: string) -> (),
    bumpWeaponStats: (plr: Player, weaponName: string, deltaBullets: number?, deltaItems: number?) -> (),
    GrantBox: (plr: Player, tier: string, count: number?) -> (),
    OpenBox: (plr: Player, tier: string) -> BoxOpenResult,
    onShot: (plr: Player) -> (),
}

type _G = GameGlobals

return {}
