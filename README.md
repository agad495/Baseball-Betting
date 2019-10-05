# Baseball-Betting
Takes Steamer projections (downloaded as CSV's from FanGraphs) and converts them into projected betting lines based off the teams playing and each team's starting lineup.                                    

# Example

Say we want to predict Yankees vs Red Sox, with a pitching matchup of Luis Severino vs Chris Sale:
```
from baseball import Baseball
from baseball_betting import BaseballBetting

steamer = Baseball('FanGraphs Leaderboard.csv', 'FanGraphs Leaderboard (1).csv', 
                            'FanGraphs Leaderboard (2).csv', 'FanGraphs Leaderboard (3).csv')

hitting = steamer.calc_RRF700()
pitching = steamer.calc_adjRA162()

ratings = BaseballBetting(hitting, pitching)
yankees = ratings.position_players('Edwin Encarnacion', 'Aaron Judge', 'Brett Gardner',
                                    'Giancarlo Stanton', 'Gary Sanchez', 'Gleyber Torres',
                                    'DJ Lemahieu', 'Giovanny Urshela', 'Didi Gregorius')
redsox = ratings.position_players('J.D. Martinez', 'Mookie Betts', 'Andrew Benintendi',
                                    'Rafael Devers', 'Xander Bogaerts', Jackie Bradley Jr.'
                                    'Brock Holt', 'Mitch Moreland', 'Christian Vazquez')
bos_nyy = ratings.result('Red Sox', 'Yankees', 'Chris Sale', 'Luis Severino', redsox, yankees)
```
This will return a dictionary in the form of {Team : [% odds to win, american odds to win, projected runs for, projected runs allowed],...}
(The projected runs for and runs allowed will seem high (like, VERY high), this is because its a projection over 162 games. Over the course of a full 162 game season, there's much less variance than over 1 game, so we project base winning percentages based off what a given team with the 8 or 9 position players and starting pitcher would achieve if this lineup/starting pitcher combination played in all 162 games. The book, 'Trading Bases' by Joe Peta does a much better job of describing this than I ever can, so check that out if you are looking to learn more.
