extends Node
class_name RoomData
const room = preload("res://Game Elements/Rooms/room.gd")


###Z ORDERS
#0-9 background enviornmental elements(flooring,etc)
#10-19 background dynamic elements(grass, floor attacks)
#20-29 Player area(player is 20, most enemies are 20)
#30-39 Filling and portals
#40-49 UI Elements
####



#the root node of each room MUST BE NAMED Root

var sci_fi_rooms : Array[Room] = [room.Create_Room(
"res://Game Elements/Rooms/sci_fi/factory1.tscn", 																				#Scene Location                       
1,																																#Num Liquids
[Globals.Liquid.Conveyer],																										#Liquid Types 
[.9],																															#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
9,																																#Num Traps              
[.75,.75,.3,.3,.3,.3,.3,.3,.3],																									#Trap Chances                                
[Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
20,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiFactory,																								#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/laser_enemy.tscn"],								#Enemies That can spawn in this room
[.2,.8],																														#Weights for those enemies to spawn
.5),room.Create_Room(																											#Chance for waves to be segmented
"res://Game Elements/Rooms/sci_fi/factory2.tscn", 																				#Scene Location                       
11,																																#Num Liquids
[Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer],																										#Liquid Types 
[.75,.75,.75,.75,.9,.5,.5,.5,.5,.5,.5],																							#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
15,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiFactory,																								#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/laser_enemy.tscn"],							#Enemies That can spawn in this room
[.9,.1],																														#Weights for those enemies to spawn
.2),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/factory3.tscn", 																				#Scene Location                       
8,																																#Num Liquids
[Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer,Globals.Liquid.Conveyer],		#Liquid Types 
[.9,.5,.5,.5,1,1,1,.5],																											#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
4,																																#Num Traps              
[.75,.5,1,.5],																													#Trap Chances                                
[Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire,Globals.Trap.Fire],														#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
35,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiFactory,																								#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/laser_enemy.tscn"],							#Enemies That can spawn in this room
[30,5],																															#Weights for those enemies to spawn
.3),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/factory4.tscn", 																				#Scene Location                       
2,																																#Num Liquids
[Globals.Liquid.Conveyer,Globals.Liquid.Conveyer],																				#Liquid Types 
[.5,.5],																														#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
5,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],				#Pathway Directions                     
30,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiFactory,																								#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/laser_enemy.tscn"],							#Enemies That can spawn in this room
[12,18],																														#Weights for those enemies to spawn
.7),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace1.tscn", 																			#Scene Location                       
4,																																#Num Liquids
[Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch],										#Liquid Types 
[.5,.5,.5,.5],																																#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
10,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiCyberspace,																							#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/binary_bot.tscn"],									#Enemies That can spawn in this room
[.33,.66],																														#Weights for those enemies to spawn
.75),																															#Chance for waves to be segmented
room.Create_Room(			
"res://Game Elements/Rooms/sci_fi/cyberspace2.tscn", 																			#Scene Location                       
5,																																#Num Liquids
[Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch],				#Liquid Types 
[.9,.25,.5,.5,.9],																												#Liquid Chances                      
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
18,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiCyberspace,																							#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/binary_bot.tscn"],									#Enemies That can spawn in this room
[.33,.66],																														#Weights for those enemies to spawn
.75),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace3.tscn", 																			#Scene Location                      
4,																																#Num Liquids
[Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch],										#Liquid Types 
[.9,.8,.5,.5],																													#Liquid Chances                       
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
12,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiCyberspace,																							#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/binary_bot.tscn"],									#Enemies That can spawn in this room
[.33,.66],																														#Weights for those enemies to spawn
.75),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace4.tscn", 																			#Scene Location                        
2,																																#Num Liquids
[Globals.Liquid.Glitch,Globals.Liquid.Glitch],																					#Liquid Types 
[.4,.5],																														#Liquid Chances                       
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
14,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiCyberspace,																							#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/binary_bot.tscn"],									#Enemies That can spawn in this room
[.33,.66],																														#Weights for those enemies to spawn
.75),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace5.tscn", 																			#Scene Location                       
4,																																#Num Liquids
[Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch],										#Liquid Types 
[.8,.9,.5,.5],																													#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
6,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down,Globals.Direction.Down,Globals.Direction.Down],		#Pathway Directions                       
16,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiCyberspace,																							#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/binary_bot.tscn"],									#Enemies That can spawn in this room
[.33,.66],																														#Weights for those enemies to spawn
.75),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace6.tscn", 																			#Scene Location                        
6,																																#Num Liquids
[Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch,Globals.Liquid.Glitch], #Liquid Types 
[.5,.5,.5,.5,.5,.5],																											#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
8,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.SciFiCyberspace,																							#RoomVariant
["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/binary_bot.tscn"],									#Enemies That can spawn in this room
[.33,.66],																														#Weights for those enemies to spawn
.75)]																															#Chance for waves to be segmented

var sci_fi_shops : Array[Room]= [room.Create_Room(
"res://Game Elements/Rooms/shops/shop_cyberspace.tscn", 																		#Scene Location                       
1,																																#Num Liquids
[Globals.Liquid.Glitch],																										#Liquid Types 
[1.0],																															#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
0,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Shop,																											#RoomType
Globals.RoomVariant.SciFiCyberspace,																							#RoomVariant
[],																																#Enemies That can spawn in this room
[],																																#Weights for those enemies to spawn
0.0),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/shops/shop_factory.tscn", 																			#Scene Location                       
2,																																#Num Liquids
[Globals.Liquid.Conveyer,Globals.Liquid.Conveyer],																				#Liquid Types 
[1.0,1.0],																														#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
0,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Shop,																											#RoomType
Globals.RoomVariant.SciFiFactory,																								#RoomVariant
[],																																#Enemies That can spawn in this room
[],																															#Weights for those enemies to spawn
0),
room.Create_Room(
"res://Game Elements/Rooms/medieval/outside1.tscn", 																		#Scene Location                       
0,																																#Num Liquids
[],																										#Liquid Types 
[],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
10,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,
Globals.RoomVariant.MedOut,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0),
room.Create_Room(
"res://Game Elements/Rooms/medieval/outside2.tscn", 																		#Scene Location                       
0,																																#Num Liquids
[Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water],																										#Liquid Types 
[.9,.9,.9,1,1],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
12,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,
Globals.RoomVariant.MedOut,																																#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0),
room.Create_Room(
"res://Game Elements/Rooms/medieval/outside3.tscn", 																		#Scene Location                       
0,																																#Num Liquids
[],																										#Liquid Types 
[],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
5,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
12,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,
Globals.RoomVariant.MedOut,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0),
room.Create_Room(
"res://Game Elements/Rooms/medieval/cave1.tscn", 																		#Scene Location                       
0,																																#Num Liquids
[Globals.Liquid.Lava,Globals.Liquid.Lava,Globals.Liquid.Lava,Globals.Liquid.Lava],												#Liquid Types 
[.8,1,.5,.5],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
5,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
12,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,
Globals.RoomVariant.MedIn,																																	#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0),
room.Create_Room(
"res://Game Elements/Rooms/medieval/cave2.tscn", 																		#Scene Location                       
2,																																#Num Liquids
[Globals.Liquid.Lava,Globals.Liquid.Lava,Globals.Liquid.Water,Globals.Liquid.Water],												#Liquid Types 
[.8,.8,.8,.8],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
5,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
12,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,
Globals.RoomVariant.MedIn,																																#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/medieval/cave3.tscn", 																		#Scene Location                       
5,																																#Num Liquids
[Globals.Liquid.Lava,Globals.Liquid.Lava,Globals.Liquid.Lava,Globals.Liquid.Lava,Globals.Liquid.Water],												#Liquid Types 
[.33,.33,.33,.33,1],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
20,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,
Globals.RoomVariant.MedIn,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0)]																															#Chance for waves to be segmented


var boss_rooms : Array[Room] = [room.Create_Room(
"res://Game Elements/Bosses/scifi/boss_room.tscn", 																			#Scene Location                       
0,																																#Num Liquids
[],																				#Liquid Types 
[],																														#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
0,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Boss,																											#RoomType
Globals.RoomVariant.SciFiFactory,																								#RoomVariant
[],																																#Enemies That can spawn in this room
[],																																#Weights for those enemies to spawn
0.0)]


var testing_room : Room = room.Create_Room(
"res://Game Elements/Rooms/testing_room.tscn", 																					#Scene Location                      
0,																																#Num Liquids
[],																																#Liquid Types 
[],																																#Liquid Chances                       
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
2,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down],									#Pathway Directions                       
2,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
Globals.RoomType.Combat,																										#RoomType
Globals.RoomVariant.MedOut,																							#RoomVariant
["res://Game Elements/Characters/robot.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
.25)
