
Parse.Cloud.afterSave("Users", function(request) {
  var UserName = request.object.get('UserName');
  var udid = request.object.get('udid');
  var status = request.object.get('Status');
  var pushQuery = new Parse.Query(Parse.Installation);
  pushQuery.equalTo('deviceType', 'ios');
  Parse.Push.send({
    where: pushQuery, 
    data: {
      alert: UserName +": " + (status == 1 ? "Онлайн" : "Оффлайн") ,
      userName:UserName,
      udid: udid,
      status: status
    }
  }, {
    success: function() {
      console.log("Success");
    },
    error: function(error) {
      throw "Got an error " + error.code + " : " + error.message;
    }
  });
});

//Каждую минуту, если пользователь больше 2-х минут, то меняю статус на оффлайн
Parse.Cloud.job("UsersToOffline", function(request, status) {
  var currentDate = new Date();
  var usersUdid = [];
  var query = new Parse.Query("Users");
  query.equalTo("Status",1);
  query.each(function(user) {
    if((currentDate - user.updatedAt)/120000 >= 1)
    {
      usersUdid.push(user.id);
      user.set("Status",0);
      user.save(null, {
  success: function(user) {
    console.log("Status:=0 - success" + user.id);
  },
  error: function(user, error) {
   console.log("Status:=0 - error"+user.id);
  }
});
    }
  }).then(function() {
    status.success("UsersToOffline - success");
    console.log(usersUdid);
  }, function(error) {
    status.error("UsersToOffline - error");
  });
});


