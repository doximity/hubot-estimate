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

You will get the most out of hubot estimate if you register your team. Note that to do so you will need to set HUBOT_PIVOTAL_TOKEN.
```
estimate team #channel-name, pivotal_project_id, [@team_member_1, @team_member_2, @team_member_N]
```
(The square brackets are required.)

By doing so, the bot will automatically post the score of the votes when all voters have voted in the specified channel. This reduces the overhead of having to ask the bot what the final score is or set up what the expected total number of voters is. Additionally, if you have a pivotal tracker board, the score will be automatically set and you will be linked to the ticket.

In a team channel discuss the ticket you'd like to estimate, ie. 123.

In a chat with your bot
```
estimate 123 as 3
> You've estimated story 123 as 3 points
```
Note that if you're not in a chat with your bot you will need @botname to address the bot.

In the team channel check if everyone is finished without seeing their votes
```
estimate voters for 123
> People who voted for 123: kleinjm, coworker1, coworker2
```

When everyone is done see all votes
```
estimate for 123
> Median vote of 5 by kleinjm: 3, coworker1: 5, coworker2: 7
```

To clear the estimate if needed
```
estimate remove 123
> Removed estimation for 123
```

Before voting you may also set a max number of voters to auto-print the vote when that number of voters has been reached. Again, this is better handled by setting a team but may be done ad hoc as well.
```
estimate max 2 for 123 # in a public channel
botname estimate 123 as 3 # user 1
botname estimate 123 as 3 # user 2
> Unanimous estimation of 3 points by user1, user2 # in the public channel
```

## Test

```bash
npm test
```

## Contributing

Thanks for your intrest in contributing! Please see our [contributing
guidelines](https://github.com/kleinjm/hubot-estimate/blob/master/CONTRIBUTING.md) for
details and feel free to reach out with any questions.

## License

[Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
