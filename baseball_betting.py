import pandas as pd
import numpy as np

class BaseballBetting():
    """Takes player ratings to predict win% for MLB games"""
    def __init__(self, batters, pitchers):
        self.batters = batters
        self.pitchers = pitchers
        
    def position_players(self, dh, *sluggers):
        """Creates subset of the Home Team's lineup, 
        then adds RRF_700, Def_162 and the number of players"""
        rows = pd.Series([])
        for s in sluggers:
            p = self.batters.loc[s]
            rows = pd.concat([p, rows])
        if dh == 0:
            rows = rows
        else:

            no_d = self.batters.loc[dh]
            no_d['Def_162'] = 0
            rows = pd.concat([no_d, rows])
        runs = rows['RRF_700'].sum()
        defense = rows['Def_162'].sum()
        players = len(rows.index)
        team = [runs, defense, players]
        return team
     
    def result(self, away, home, a_pitcher, h_pitcher, a_lineup, h_lineup):
        """Calcs predicted win% and converts it to American Moneyline"""
        away_p = self.pitchers.loc[a_pitcher]
        a = away_p['RA_162']
        home_p = self.pitchers.loc[h_pitcher]
        h = home_p['RA_162']
        a_win = (a_lineup[0] ** 1.83) / ((a_lineup[0] ** 1.83) + 
                                         ((a - a_lineup[1])**1.83))
        h_win = (h_lineup[0] ** 1.83) / ((h_lineup[0] ** 1.83) + 
                                         ((h - h_lineup[1])**1.83))
        a_win_bayes = (a_win*(1-h_win)) / ((a_win*(1-h_win))+(h_win*(1-a_win)))
        h_win_bayes = 1 - a_win_bayes
        a_win_bayes_hf = (a_win_bayes*(1-.53)) / ((a_win_bayes*(1-.53))+(h_win_bayes*(.53)))
        h_win_bayes_hf = 1 - a_win_bayes_hf
        if a_win_bayes_hf > 0.5:
            a_odds = (a_win_bayes_hf / (1 - a_win_bayes_hf)) * -100
        else:
            a_odds = ((1 / a_win_bayes_hf) - 1) * 100
        h_odds = a_odds * -1
        game = {away : [a_win_bayes_hf, a_odds, a_lineup[0], (a - a_lineup[1])],
               home: [h_win_bayes_hf, h_odds, h_lineup[0], (h - h_lineup[1])]}
        print(game)