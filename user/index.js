var
  dynamoose = require('dynamoose');
  utils = require('../utils');

var userSchema = new dynamoose.Schema({
  slackUsername: String,
  jiraUsername: String,
  jiraToken: String,
  jiraTokenSecret: String
});

var User = dynamoose.model('users', userSchema);

var functions = {
  update: function(dynaId, updates) {
    console.log('I AM UPDATING USER ' + dynaId)
    return new Promise(function(resolve, reject) {
      User.update(
        { _id: dynaId },
        { $PUT: updates },
        function(err, result) {
          if (err) {
            return reject(err);
          } else {
            User.queryOne({
              _id: dynaId
            }, function(err, user) {
              if(!err) {
                return resolve(user)
              } else {
                return reject(err)
              }
            })
          }
        }
      );
    })
  },
  create: function(userObj) {
    return new Promise(function (resolve, reject) {

      newUser = new User ({
        slackUsername: userObj.slackUsername
        // jiraUsername: utils.addJiraMarkupToUsername(userObj.jiraUsername),
        // jiraToken: userObj.jiraToken,
        // jiraTokenSecret: userObj.jiraTokenSecret
      });
      newUser.save(function (err, user) {
        if (err) {
          return reject(err)
        } else {
          return resolve(user)
        }
      });

    })
  },
  getByJiraUsername: function(jiraUsername) {
    return new Promise(function(resolve, reject) {

      User.QueryOne({
        jiraUsername: jiraUsername
      }, function(err, user) {
        if(!err) {
          return resolve(user)
        } else {
          return reject(err)
        }
      })

    });
  },
  getBySlackUsername: function(slackUsername) {
    return new Promise(function(resolve, reject) {
      console.log("GETTING USER")
      User.queryOne({
        slackUsername: slackUsername
      }, function(err, user) {
        console.log("ERROR" + err)
        console.log("USER" + user)
        if(!err) {
          return resolve(user)
        } else {
          return reject(err)
        }
      })

    });
  },
  getBySlackUserId: function(slackUserId) {
    return new Promise(function(resolve, reject) {

      User.queryOne({
        slackUserId: slackUserId
      }, function(err, user) {
        if(!err) {
          return resolve(user)
        } else {
          return reject(err)
        }
      })

    });
  }
}

module.exports = functions;
