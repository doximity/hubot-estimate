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
