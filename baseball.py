import pandas as pd
import numpy as np

class Baseball():
    """A class to set up player ratings to be used for predicting win% for specific games"""
    def __init__(self, hitters, hurlers, stadiums, seasons):
        """Read and setup pitcher and park factor dataframes"""
        self.bat = pd.read_csv(hitters)
        self.pitch = pd.read_csv(hurlers)
        self.parks = pd.read_csv(stadiums)
        self.constants = pd.read_csv(seasons)
        self.batters = self.bat[['Name', 'Team', 'G', 'PA', 'wRC+', 'BsR', 'Def', 'WAR']]
        self.pitchers = self.pitch[['Name', 'Team', 'GS', 'G', 'IP', 'FIP']]
        self.pitchers = self.pitchers[(self.pitchers.Name != 'Caleb Smith') | (self.pitchers.Team != 'Giants')]

        
    def calc_RRF700(self):
        """Calculating Runs Responsible For if a batter had 700 PA"""
        self.batters['RRF'] = ((self.batters['wRC+'] / 100) * .126 * self.batters['PA']) + self.batters['BsR']
        self.batters['RRF_700'] = self.batters['RRF'] * (700 / self.batters['PA'])
        """Calculating defensive run value if a fielder played 162 Games"""
        self.batters['Def_162'] = self.batters['Def'] * (162 / self.batters['G'])
        self.batters.set_index(self.batters.columns[0])
        return self.batters.set_index(self.batters.columns[0])
               
    def calc_adjRA162(self):
        """Calculating adjRA162 
        (avg no. of runs a starter would allow if he pitched all 162 games)""" 
        """Calc the park and league 
        adjusted Runs Allowed for individual pitchers"""
        self.pitchers = pd.merge(self.pitchers, self.parks[['Team', 'Basic']])
        fip = 4.59/4.41
        self.pitchers['lgfip'] = np.where(self.pitchers['Team']=='Angels', 1 / fip, 
                                          np.where(self.pitchers['Team']=='Astros', 1 / fip, 
                                                   np.where(self.pitchers['Team']=='Athletics', 1 / fip,
                                                            np.where(self.pitchers['Team']=='Blue Jays', 1 / fip,
                                                                     np.where(self.pitchers['Team']=='Mariners', 1 / fip,
                                                                              np.where(self.pitchers['Team']=='Rangers', 1 / fip,
                                                                                       np.where(self.pitchers['Team']=='Yankees', 1 / fip,
                                                                                                np.where(self.pitchers['Team']=='Red Sox', 1 / fip,
                                                                                                         np.where(self.pitchers['Team']=='Rays', 1 / fip,
                                                                                                                  np.where(self.pitchers['Team']=='Orioles', 1 / fip,
                                                                                                                           np.where(self.pitchers['Team']=='Tigers', 1 / fip,
                                                                                                                                    np.where(self.pitchers['Team']=='Twins', 1 / fip,
                                                                                                                                             np.where(self.pitchers['Team']=='Indians', 1 / fip,
                                                                                                                                                      np.where(self.pitchers['Team']=='White Sox', 1 / fip,
                                                                                                                                                      np.where(self.pitchers['Team']=='Royals', 1 / fip, fip)))))))))))))))
        self.pitchers['adjRA'] = ((self.pitchers['FIP'] * self.pitchers['IP'] / 9) * 
                                  (100 / self.pitchers['Basic']) * self.pitchers['lgfip'])
        
        """Balance Runs Allowed by pitchers and Runs Responsible for by batters.
        Note: you must have run the Batters class already."""
        self.pitchers['adjRA_bal'] = (self.batters['RRF'].sum() / self.pitchers['adjRA'].sum()) * self.pitchers['adjRA']
        
        relievers = self.pitchers[self.pitchers.G - self.pitchers.GS > 5]
        bullpens = relievers.groupby('Team').sum()
        bullpens.rename(columns = {'IP' : 'BPIP', 'adjRA_bal' : 'BPRA'}, inplace=True)
        bullpens['BPIP'] = bullpens['BPIP'] / 162
        bullpens = bullpens.reset_index(level=['Team'])
        self.pitchers = pd.merge(self.pitchers, bullpens[['Team', 'BPIP', 'BPRA']])
        
        """For players who start games but also come out of the bullpen,
        recalc adjRA_bal as adjRA_balr"""
        self.pitchers['adjRA_balr'] = np.where(self.pitchers['G']-self.pitchers['GS'] > 5, 
                                 (self.pitchers['FIP'] * (self.pitchers['IP']-(self.pitchers['G']-self.pitchers['GS'])) / 9) * (100 / self.pitchers['Basic']),
                                 0)
        
        """Calc the average number of runs allowed a starter would have if he theoretically
        started every single game. Based off his skill level and the skill of his bullpen."""
        self.pitchers['RA_162'] = np.where(self.pitchers['G'] - self.pitchers['GS'] <= 5, 
                             ((162/self.pitchers['GS'])*self.pitchers['adjRA_bal']) + ((9-(self.pitchers['IP']/self.pitchers['GS']))/self.pitchers['BPIP']) * self.pitchers['BPRA'],
                             ((162/self.pitchers['GS'])*self.pitchers['adjRA_balr']) + ((9-((self.pitchers['IP']-(self.pitchers['G']-self.pitchers['GS']))/self.pitchers['GS']))/self.pitchers['BPIP']) * self.pitchers['BPRA'])
        return self.pitchers.set_index(self.pitchers.columns[0])

