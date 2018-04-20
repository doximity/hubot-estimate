# hubot-estimate
> Async private voting for estimation meetings

## Install

```bash
npm install hubot-estimate
```

Add the following to your `external-scripts.json` file:
```js
[
  "hubot-estimate"
]
```

## Usage

You will get the most out of hubot estimate if you register your team.
```
estimate team #channel-name, pivotal_project_id, [team_members]
```
By doing so, the bot will automatically post the score of the votes when all voters have voted. This reduces the overhead of having to ask the bot what the final score is or set up what the expected total number of voters is. Additionally, if you have a pivotal tracker board, the score will be automatically set and you will be linked to the ticket.

In a team channel discuss the ticket you'd like to estimate, ie. 123.

In a chat with your bot
```
estimate 123 as 3
> You've estimated story 123 as 3 points
```

In the team channel check if everyone is finished without seeing their votes
```
botname estimate voters for 123
> People who voted for 123: kleinjm, coworker1, coworker2
```

When everyone is done see all votes
```
botname estimate for 123
> Median vote of 5 by kleinjm: 3, coworker1: 5, coworker2: 7
```

To clear the estimate if needed
```
botname estimate remove 123
> Removed estimation for 123
```

### Test

```bash
npm test
```

## License

[MIT](http://vjpr.mit-license.org)
