library(tidyverse)
library(plyr)
library(dplyr)

Batters = read.csv('FanGraphs Leaderboard.csv')
Pitchers = read.csv('FanGraphs Leaderboard (1).csv')
Steamer = rbind.fill(Batters, Pitchers)
Steamer[is.na(Steamer)] = 0
Steamer = Steamer[,-27]
Steamer = Steamer[,-23]
Steamer = Steamer[,-17]
constants = read.csv('FanGraphs Leaderboard (3).csv')
Steamer$RRF = (((Steamer$wRC. / 100) * subset(constants, Season==2019)$R.PA) * Steamer$PA) + Steamer$BsR
Steamer$RA = (Steamer$FIP * Steamer$IP) / 9
colnames(Steamer)[1] = "Name"

detach(package:plyr)
Teams = Steamer %>%
  filter(Team != "") %>%
  group_by(Team) %>%
  summarise(WAR = sum(WAR), RF = sum(RRF), RA = sum(RA), Def = sum(Def), BsR = sum(BsR))
Teams$League = c("AL", "AL", "AL", "AL", "NL", "NL", "NL", "NL", "NL", "NL", "NL", "AL", "AL", "NL", "NL", "NL", "AL",
                 "NL", "NL", "NL", "AL", "AL", "AL", "NL", "NL", "AL", "AL", "AL", "AL", "AL")
Teams$BsR = round(Teams$BsR, 3)
Teams = Teams[,c(1,7,2,3,4,5,6)]
PF = read.csv('FanGraphs Leaderboard (2).csv')
PF = PF[,-1]
PF[,2:13] = PF[,2:13] / 100
names(PF) = c("Team", "Basic", "B1", "B2", "B3", "RH", "K", "BoB", "GB", "FB", "LD", "IFFB", "FIPf")
PF$Team = as.character(PF$Team)
PF = PF[order(PF$Team),]
Teams$ParkFactor = PF$Basic
lgFIP = 4.58/4.43
Teams$lgFIP = ifelse(Teams$League == "AL", 1/lgFIP, lgFIP)
Teams$RA = (Teams$RA / Teams$ParkFactor * Teams$lgFIP) - Teams$Def
RunAdjustor = sum(Teams$RF) / sum(Teams$RA)
Teams$RF = Teams$RF / RunAdjustor

Teams$WinPct = (Teams$RF^1.83) / (Teams$RF^1.83 + Teams$RA^1.83)
Teams$Wins = Teams$WinPct * 162
WinAdjustor = sum(Teams$Wins) / 2430
Teams$Wins = Teams$Wins / WinAdjustor
Team.Names = as.character(Teams$Team)
Parks = as.data.frame(c(Teams[,1], Teams[,8:9]))
Parks = rbind(Parks, c("", 1,1))
Parks$ParkFactor = as.numeric(Parks$ParkFactor)
Parks$lgFIP = as.numeric(Parks$lgFIP)

ggplot(Teams, aes(x=RF, y=RA)) +
  geom_point() +
  geom_text(label=Team.Names, nudge_x=1, nudge_y=1) +
  geom_vline(xintercept = mean(Teams$RF)) +
  geom_hline(yintercept = mean(Teams$RA))

ggplot(Teams, aes(x=Def, y=BsR)) +
  geom_point() +
  geom_text(label=Team.Names, nudge_x=1, nudge_y=1) +
  geom_vline(xintercept = mean(Teams$Def)) +
  geom_hline(yintercept = mean(Teams$BsR))

ggplot(Teams, aes(x=Wins, y=Win.Total)) +
  geom_point() +
  geom_text(label=Team.Abbr, nudge_x=0.1, nudge_y=.75) +
  geom_abline()


SteamerbyTeam = Steamer[order(Steamer$Team),]
SteamerbyTeam = subset(SteamerbyTeam, SteamerbyTeam$G > 0 & SteamerbyTeam$Team!="")
SteamerbyTeam = subset(SteamerbyTeam, Name!="Luis Castillo" | Team!="Diamondbacks")
SteamerbyTeam = subset(SteamerbyTeam, Name!="Jose Martinez" | Team!="Dodgers")
SteamerbyTeam = subset(SteamerbyTeam, Name!="Jose Martinez" | Team!="Twins")
SteamerbyTeam = subset(SteamerbyTeam, Name!="Jose Martinez" | Team!="Orioles")
SteamerbyTeam = subset(SteamerbyTeam, Name!="Jose Ramirez" | Team!="Royals")
SteamerbyTeam = subset(SteamerbyTeam, Name!="Jose Ramirez" | Team!="Red Sox")
SteamerbyTeam = merge(SteamerbyTeam, Parks, by="Team")
SteamerbyTeam$adjRA = (SteamerbyTeam$RA / SteamerbyTeam$ParkFactor) * SteamerbyTeam$lgFIP
Run.Adj = sum(SteamerbyTeam$RRF) / sum(SteamerbyTeam$adjRA)
SteamerbyTeam$adjRA = SteamerbyTeam$adjRA * Run.Adj
bull = subset(SteamerbyTeam, (G - GS) >= 5 & Team != "" & IP > 0)
bull$IP = with(bull, G - GS)
bull$adjRA = with(bull, ((IP * FIP) / 9) / ParkFactor * lgFIP)
bp = bull %>%
  filter((G - GS) >= 5 & Team != "") %>%
  group_by(Team) %>%
  summarise(BPIP = sum(IP) / 162, BPRA = sum(adjRA), BPRI = sum(BPRA/162*9/BPIP))
SteamerbyTeam = merge(SteamerbyTeam, bp, by="Team")
SteamerbyTeam$RA162 = with(SteamerbyTeam, ifelse(G-GS < 5, (162/GS*adjRA)+((9-(IP/GS))/BPIP)*BPRA, (162/GS*(((IP-(G-GS))*FIP/9)/ParkFactor*lgFIP)+((9-((IP-(G-GS))/GS))/BPIP)*BPRA)))
SteamerbyTeam$Def162 = (162/SteamerbyTeam$G) * SteamerbyTeam$Def
SteamerbyTeam$RRF162 = (700/SteamerbyTeam$PA) * SteamerbyTeam$RRF
SteamerbyTeam = subset(SteamerbyTeam, select = -c(BPRI))
SteamerbyTeam = subset(SteamerbyTeam, Name!="Will Smith" | Team!="Giants")

Game = function(A, H, B, X, Y, Z){
  home = subset(Teams, Team == H)
  away = subset(Teams, Team == A)
  hp = subset(SteamerbyTeam, Name == X)
  ap = subset(SteamerbyTeam, Name == B)
  hb = Z
  ab = Y
  t = c(A, H)
  h = hb[1]^1.83 / (hb[1]^1.83 + (hp[1,"RA162"]-hb[2])^1.83)
  a = ab[1]^1.83 / (ab[1]^1.83 + (ap[1,"RA162"]-ab[2])^1.83)
  h1 = (h*(1-a))/((h*(1-a))+((a*(1-h))))
  a1 = 1 - h1
  h2 = (h1*(.53))/((h1*(.53))+((.47*(1-h1))))
  a2 = 1 - h2
  w = unlist(c(a2, h2))
  g = data.frame(Team = t, WinPct = w)
  g$Odds = ifelse(g$WinPct > .5, g$WinPct/(1-g$WinPct)*-100, (1-g$WinPct)/g$WinPct*100)
  g$RF = c(ab[1],hb[1])
  g$RA = c((ap[1,"RA162"]-ab[2]),(hp[1,"RA162"]-hb[2]))
  g$RunLine = with(g, (WinPct*(.73)))
  return(g)
}

Lineup_AL = function(A, B, C, D, E, K, L, I, J, M){
  hb = subset(SteamerbyTeam, Name == A | Name == B | Name == C | Name == D | Name == E | Name == I | Name == J | Name == K | Name == M)
  dh = subset(SteamerbyTeam, Name == M)
  rf = sum(hb$RRF162)
  def = sum(hb$Def162) - sum(dh$Def162)
  num = nrow(hb)
  runs = c(rf, def, num)
  return(runs)
}

Lineup_NL = function(A, B, C, D, E, G, H, I, J, K){
  hb = subset(SteamerbyTeam, Name == A | Name == B | Name == C | Name == D | Name == E | Name == G | Name == J | Name == I | Name == K)
  rf = sum(hb$RRF162)
  def = sum(hb$Def162)
  num = nrow(hb)
  runs = c(rf, def, num)
  return(runs)
}

Yankees = Lineup_AL('DJ LeMahieu', 'Aaron Judge', 'Gleyber Torres', 'Gary Sanchez', 
                 'Miguel Andujar', 'Brett Gardner', '', 'Luke Voit', 'Mike Tauchman', 
                 'Giancarlo Stanton')
Astros = Lineup_AL('George Springer', 'Jose Altuve', 'Alex Bregman', 'Michael Brantley', 
                   'Yuli Gurriel', 'Josh Reddick', '', 'Carlos Correa', 'Martin Maldonado', 
                   'Yordan Alvarez')
nyy_hou = Game("Yankees", "Astros", "Gerrit Cole", "Justin Verlander", Yankees, Astros)

