const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const geometry = require("spherical-geometry-js");

module.exports = {
  calculatePolygonAreaOnCreate: functions
    .region("asia-east2")
    .database.ref(
      "/data/{userUid}/{surveyName}/{categoryName}/polygons/{polygonId}"
    )
    .onCreate((snapshot, context) => {
      // Grab the current value of what was written to the Realtime Database.
      const polygonData = snapshot.val();
      const vertex = polygonData.vertex;
      console.log("testvertex = " + vertex);
      let area = calculateArea(vertex);
      snapshot.ref.parent.parent
        .child("counter")
        .ref.transaction(function(currentCount) {
          return (currentCount || 0) + 1;
        });
      return snapshot.ref.update({ area: area });
    }),
  calculatePolygonAreaOnHttp: functions
    .region("asia-east2")
    .https.onRequest((req, res) => {
      var vertex = req.query.vertex;
      vertex = JSON.parse(vertex);
      var getArea = calculateArea(vertex);
      res.send("" + getArea);
    }),
  calculateLineDistanceOnHttp: functions
    .region("asia-east2")
    .https.onRequest((req, res) => {
      var vertex = req.query.vertex;
      vertex = JSON.parse(vertex);
      var getLength = haversine_distance(vertex);
      res.send("" + getLength);
    }),
  onPolygonDelete: functions
    .region("asia-east2")
    .database.ref(
      "/data/{userUid}/{surveyName}/{categoryName}/polygons/{polygonId}"
    )
    .onDelete((snapshot, context) => {
      // console.log("deleted successfully");
      return snapshot.ref.parent.parent
        .once("value")
        .then(function(dataSnapshot) {
          if (
            !dataSnapshot.child("polygons").exists() &&
            !dataSnapshot.child("polylines").exists()
          ) {
            // console.log("all polygons are deleted");
            return dataSnapshot.ref.remove().then(function() {
              return;
            });
          } else {
            // console.log("polygons still exist...");
            // update counter
            dataSnapshot
              .child("counter")
              .ref.transaction(function(currentCount) {
                return (currentCount || 0) - 1;
              });
          }
          return dataSnapshot;
        });
    }),
  onPolylineDelete: functions
    .region("asia-east2")
    .database.ref(
      "/data/{userUid}/{surveyName}/{categoryName}/polylines/{polylineId}"
    )
    .onDelete((snapshot, context) => {
      // console.log("deleted successfully");
      return snapshot.ref.parent.parent
        .once("value")
        .then(function(dataSnapshot) {
          if (
            !dataSnapshot.child("polygons").exists() &&
            !dataSnapshot.child("polylines").exists()
          ) {
            // console.log("all polylines are deleted");
            return dataSnapshot.ref.remove().then(function() {
              return;
            });
          } else {
            // console.log("polygons still exist...");
            // update counter
            dataSnapshot
              .child("linecounter")
              .ref.transaction(function(currentCount) {
                return (currentCount || 0) - 1;
              });
          }
          return dataSnapshot;
        });
    }),
  updateCounterOnPolylineCreate: functions
    .region("asia-east2")
    .database.ref(
      "/data/{userUid}/{surveyName}/{categoryName}/polylines/{polylineId}"
    )
    .onCreate((snapshot, context) => {
      // Grab the current value of what was written to the Realtime Database.
      snapshot.ref.parent.parent
        .child("linecounter")
        .ref.transaction(function(currentCount) {
          return (currentCount || 0) + 1;
        });
    })
};

function calculateArea(vertex) {
  let coords = [];
  vertex.forEach(v => {
    let element = v.split(",");
    coords.push(new geometry.LatLng(element[0], element[1]));
  });
  return geometry.computeArea(coords);
}
function haversine_distance(mk1, mk2) {
  var R = 3958.8; // Radius of the Earth in miles
  var rlat1 = mk1.position.lat() * (Math.PI / 180); // Convert degrees to radians
  var rlat2 = mk2.position.lat() * (Math.PI / 180); // Convert degrees to radians
  var difflat = rlat2 - rlat1; // Radian difference (latitudes)
  var difflon = (mk2.position.lng() - mk1.position.lng()) * (Math.PI / 180); // Radian difference (longitudes)

  var d =
    2 *
    R *
    Math.asin(
      Math.sqrt(
        Math.sin(difflat / 2) * Math.sin(difflat / 2) +
          Math.cos(rlat1) *
            Math.cos(rlat2) *
            Math.sin(difflon / 2) *
            Math.sin(difflon / 2)
      )
    );
  return d;
}

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
