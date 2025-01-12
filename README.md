 This is my first forray into modding. The idea is replace the vanilla method of mining with subsurface mining. I think this has potential to add additional constraints that make mining and setting up outposts more engaging.


Essentially mashing up code from both factorissimo (surface-to-surface travel and connection for moving fluids/material/electric/signals) and Red-mews' diggy scenario (mining/expanding/interacting with rocks) 



 
Goals:
  - Able to use mine surface for subsurface travel.
  - Methods for transfering things in/out of mine (factorissimo code provides a lot of initial utility tied to the "factory building" due to connections, can I make it so connections are seperated from the building and instead with entities like pumps/loaders where 
location in mine cooresponds to connection on planet surface? Trains at some point)
  - Creating a mine entrance will be blocked if location underneath has buildings.
  - Blocking mine expansion if it would expand into the ocean, but allowing expansion if under "ponds". Perhaps multiple levels to go under oceans?
  - resources (copper/iron/uranium) come from rocks, so the amount of time to "mine out" a rock should be commensurate with the distance from starting area (like in vanilla ore patches).
    - Rock mining automation. AAI industries mining vehicle to automate rock mining? Roboport automation?
    - Explore constant resources from rocks vs one big end of life payload
    - Allow reckless destruction of rocks, which would produce *much less* resources, but allow you to quickly expand the mine (to reach new resource concentration or create a sub-surface travel path)
- Some very sparse resources patches on the surface that indicate richer resources underground. But not every underground resource concentration will be indicated with surface patches.
    - Prospecting tool to find more resources.
- Limit what can be built in mine. Technology tiers expand what can be constructed in mine
- Limit mine expansion due to cave-in risk (no actual cave in) Require unlocked support strucutres (not just wall. some more significant , maybe at same time as rail support?) This limits viable footprint in early game


MVP Goal:
- Mine entrances all connect to the same mine surface
- mirror planet surface ore patch in mine surface which are uncovered by removing rocks. Then reduce planet patch 
- utilize factorissimo connections for transfers
- require electric poles
- unlimited mine expansion
- limit builing construction
  
