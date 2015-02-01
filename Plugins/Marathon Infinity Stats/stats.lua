Triggers = {}

function Triggers.init(restored)

   for p in Players() do
      if p.local_ then
         local_player = p
      end
   end

   stats = {}

   stats["start tick"] = Game.ticks
   stats["player name"] = local_player.name
   stats["player color"] = local_player.color.mnemonic
   stats["player team"] = local_player.team.mnemonic
   stats["difficulty"] = Game.difficulty.mnemonic
   stats["game type"] = Game.type.mnemonic
   stats["level"] = Level.name
   stats["level index"] = Level.index
   stats["map checksum"] = Level.map_checksum
   stats["players"] = # Players

   stats["scenario name"] = "Marathon Infinity"
   stats["engine version"] = Game.version
   
   if restored then
      stats["restored"] = 1
   end
end

function Triggers.cleanup()

   stats["end tick"] = Game.ticks
   if Level.completed then
      stats["level completed"] = 1
   end

   -- only check multiplayer wins if the game finishes
   -- corollary: untimed games with no kill limit never count as wins!
   local find_winner = false
   if Players[0].disconnected then
      -- gatherer went away, game was interrupted
      stats["interrupted"] = 1

   elseif Game.time_remaining == 0 then
      find_winner = true

   elseif Game.kill_limit > 0 then
      for p in Players() do
         local total_kills = 0
         for pp in Players() do
            -- don't count suicides
            if p ~= pp then
               total_kills = total_kills + p.kills[pp]
            end
         end
         if total_kills >= Game.kill_limit then
            find_winner = true
            break
         end
      end
   end

   -- determine a winner!
   if # Players > 1 and Game.type == "kill monsters" then
      -- emfh
      local scores = {}
      for p in Players() do 
         scores[p] = 0
         -- count up all the player's kills
         for pp in Players() do
            scores[p] = scores[p] + p.kills[pp]
         end
         -- subtract times he was killed (by other players and himself)
         for pp in Players() do
            scores[p] = scores[p] - pp.kills[p]
         end
      end
   
      local winner = local_player
      local ranking = 1
      for k, v in pairs(scores) do
         if v > scores[winner] then
            winner = k
         end
         if v > scores[local_player] then
            ranking = ranking + 1
         end
      end

      if find_winner then
         stats["ranking"] = ranking
         if winner == local_player then
            stats["winner"] = 1
         end
      end

   elseif Game.type == "king of the hill" 
      or Game.type == "kill the man with the ball" then
      local winner = local_player
      local ranking = 1
      for p in Players() do
         if p.points > winner.points then
            winner = p
         end
         if p.points > local_player.points then
            ranking = ranking + 1
         end
      end

      if find_winner then
         stats["ranking"] = ranking
         if winner == local_player then
            stats["winner"] = 1
         end
      end
      stats["points"] = local_player.points

   elseif Game.type == "tag" then
      local winner = local_player
      local ranking = 1
      for p in Players() do
         if p.points < winner.points then
            winner = p
         end
         if p.points < local_player.points then
            ranking = ranking + 1
         end
      end

      if find_winner then
         stats["ranking"] = ranking
         if winner == local_player then
            stats["winner"] = 1
         end
      end
      stats["points"] = local_player.points
   end
   
   -- count polygons and lines
   counted_lines = {}
   for p in Polygons() do
      increment("polygons")
      if p.visible_on_automap then
         increment("visible polygons")
      end
      for l in p.lines() do
         if not counted_lines[l.index] then
            increment("lines")
            if l.visible_on_automap then
               increment("visible lines")
            end
            counted_lines[l.index] = 1
         end
      end
   end

   Statistics = {}
   Statistics.parameters = stats
end

function Triggers.projectile_created(projectile)
   if projectile.type ~= "fist"
      and projectile.owner == local_player.monster then
      increment(projectile.type.mnemonic .. "s fired")
   end
end

function Triggers.monster_killed(monster, aggressor, projectile)
   if aggressor == local_player then
      increment(monster.type.mnemonic .. " kills")
   
      if projectile.type == "fist" then
         increment(monster.type.mnemonic .. " punch kills")
      end
   end
end

function Triggers.monster_damaged(_, aggressor_monster, _, _, projectile)
   if aggressor_monster == local_player.monster and projectile then
      if projectile.type ~= "fist" and not projectile._hit then
         projectile._hit = true
         increment(projectile.type.mnemonic .. "s hit")
      end
   end
end

function Triggers.player_damaged(_, aggressor_player, _, _, _, projectile)
   if aggressor_player == local_player and projectile then
      if projectile.type ~= "fist" and not projectile._hit then
         projectile._hit = true
         increment(projectile.type.mnemonic .. "s hit")
      end
   end
end

function Triggers.projectile_switch(projectile, side)
   if projectile.type == "fist" and projectile.owner == local_player.monster then
      increment("switches punched")
   end
end

function Triggers.tag_switch(_, player, side)
   if player == local_player and side.control_panel and side.control_panel.uses_item then
      increment("chips inserted")
   end
end

function Triggers.terminal_enter(_, player)
   if player == local_player then
      increment("terminals activated")
   end
end

function Triggers.player_killed(victim, aggressor)
   if victim == local_player then
      increment("deaths")
      
      if aggressor == local_player then
         increment("suicides")
      end

      --stats["death polygon"] = local_player.polygon.index
   end
   
   if aggressor == local_player then
      increment("kills")
   end
end

function increment(key)
   if stats[key] then
      stats[key] = stats[key] + 1
   else
      stats[key] = 1
   end
end
