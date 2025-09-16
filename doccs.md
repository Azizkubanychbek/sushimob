Map
Creating a map 
To display a map, add a MapWidget to your tree:

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

class SimpleMapScreen extends StatelessWidget {
  const SimpleMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sdkContext = sdk.DGis.initialize();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: sdk.MapWidget(
        sdkContext: sdkContext,
        mapOptions: sdk.MapOptions(),
      ),
    );
  }
}
The main object for managing the map is a MapWidgetController, which is private in the MapWidget. To get access to the MapWidgetController, create it manually and pass it to the MapWidget as a parameter:

class SimpleMapScreen extends StatelessWidget {
  const SimpleMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sdk.Context sdkContext = sdk.DGis.initialize();
    final sdk.MapWidgetController mapWidgetController = sdk.MapWidgetController();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: sdk.MapWidget(
        sdkContext: sdkContext,
        mapOptions: sdk.MapOptions(),
        controller: mapWidgetController,
      ),
    );
  }
}
To get a Map object, you can call the getMapAsync() method. This method works asynchronously, so it is safe to call it at any point in the lifecycle, starting with the initState().

This is the first time the map is available, so you can perform different operations with the map within the getMapAsync() method. All operations described later in this section imply that the map has already been initialized.

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

sdk.Map? sdkMap = null;

@override
initState() {
  super.initState();
  mapWidgetController.getMapAsync((map) {
    sdkMap = map;
  });
}
Map data sources
In some cases, to add objects to the map, you need to create a data source. Data sources act as object managers: instead of adding objects to the map directly, you add a data source to the map and add or remove objects from the data source.

There are different types of data sources: moving markers, routes that display current traffic, custom geometric shapes, etc. Each type of data source has a corresponding class.

The general workflow of working with data sources looks like this:

// Create a data source
final sdk.MyLocationMapObjectSource locationSource = sdk.MyLocationMapObjectSource(sdkContext);

// Add the data source to the map
map?.addSource(locationSource);
To remove the created data source and all the objects associated with it, call the removeSource() method:

map?.removeSource(locationSource);
You can get a list of all active data sources using the map.sources property.

Offline mode 
To configure the offline mode of the map:

Complete preparation steps to enable the map to work with preloaded data.

Add a map data source. Use the createDgisSource() function and set one of the following values to the workingMode parameter:

OFFLINE - to always use preloaded data only.
HYBRID_ONLINE_FIRST - to primarily use online data from 2GIS servers. Preloaded data is used only if it matches online data or data cannot be obtained from the servers.
HYBRID_OFFLINE_FIRST - to primarily use preloaded data. Online data from 2GIS servers is used only if preloaded data is missing.
final dgisSource = sdk.DgisSource.createDgisSource(
  sdkContext,
  sdk.DgisSourceWorkingMode.hybridOfflineFirst,
);
When creating a map, specify the created source in MapOptions:

final  mapOptions = sdk.MapOptions(sources: [dgisSource]);

// Now MapOptions can be passed to MapWidget
sdk.MapWidget(
  sdkContext: sdkContext,
  mapOptions: mapOptions,
  controller: mapWidgetController,
);
Adding objects 
To add dynamic objects to the map (such as markers, lines, circles, and polygons), create a MapObjectManager, specifying the map object. Deleting an object manager removes all the associated objects from the map, so save it in activity.

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

final sdk.MapObjectManager mapObjectManager = sdk.MapObjectManager(map)
You can add objects to the map using the addObject() and the addObjects() methods. For each dynamic object, you can specify a userData field to store arbitrary data. After their creation, object settings can be changed.

To remove objects from the map, use the removeObject() and the removeObjects() methods. To remove all objects, use the removeAll() method.

MapObjectManager is an object container. As long as objects must be presented on the map, MapObjectManager must be stored on the class level.

Marker
To add a marker to the map, create a Marker object, specifying the required options in MarkerOptions, and pass it to the addObject() method of the object manager.

The only required parameter is the coordinates of the marker (position).

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

final sdk.Marker marker = sdk.Marker(
    sdk.MarkerOptions(
        position: sdk.GeoPointWithElevation(
          latitude: sdk.Latitude(55.752425),
          longitude: sdk.Longitude(37.613983),
        )
      ),
    );
    mapObjectManager.addObject(marker);
To change the marker icon, specify an Image object as the icon parameter. You can create Image using the following functions:

loadLottieFromAsset()
loadLottieFromFile()
loadPngFromAsset()
loadPngFromFile()
loadSVGFromAsset()
loadSVGFromFile()
import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

final sdk.ImageLoader loader = sdk.ImageLoader(_sdkContext);
final sdk.Image icon = loader.loadSVGFromAsset("assets/icons/bridge.svg");

final marker = sdk.Marker(
  sdk.MarkerOptions(
    position: sdk.GeoPointWithElevation(
      latitude: sdk.Latitude(55.752425),
      longitude: sdk.Longitude(37.613983),
      icon = icon
    )
  ),
);
To update settings of an already created marker, set new values to the Marker object parameters: see the full list of available parameters in the Marker description.

// Changing marker coordinates
marker.position = const sdk.GeoPointWithElevation(
  latitude: sdk.Latitude(55.74460317215391),
  longitude: sdk.Longitude(37.63435363769531),
);

// Changing an icon
late sdk.ImageLoader loader;
marker.icon = loader.loadSVGFromAsset("Path to SVG");

// Changing the icon anchor point
marker.anchor = const sdk.Anchor(x:0.5, y:0.5);

// Changing the icon opacity
marker.iconOpacity = const sdk.Opacity(0.5);

// Changing the marker label
marker.text = 'Text';

// Changing the label style
marker.textStyle = sdk.TextStyle();

// Changing the marker draggability flag
marker.isDraggable = false;

// Changing the target marker width
marker.iconWidth = const sdk.LogicalPixel(10);

// Changing the marker rotation angle relative to the north direction
marker.iconMapDirection = sdk.MapDirection(0.5);

// Changing the flag of animating the marker appearance
marker.animatedAppearance = true;
Line
To draw a line on the map, create a Polyline object, specifying the required options in PolylineOptions, and pass it to the addObject() method of the object manager.

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

// Coordinates of the vertices of the polyline
final sdk.GeoPoint point1 = sdk.GeoPoint(latitude: sdk.Latitude(55.7), longitude: sdk.Longitude(37.6));
final sdk.GeoPoint point2 = sdk.GeoPoint(latitude: sdk.Latitude(55.8), longitude: sdk.Longitude(37.7));
final sdk.GeoPoint point3 = sdk.GeoPoint(latitude: sdk.Latitude(55.9), longitude: sdk.Longitude(37.8));
final sdk.GeoPoint geopoints = <sdk.GeoPoint>[point1,point2,point3]

// Create a polyline
final sdk.Polyline polyline = sdk.Polyline(
  sdk.PolylineOptions(
    points: geopoints,
    width: sdk.LogicalPixel(2),
  ),
);

// Add the polyline to the map
mapObjectManager.addObject(polyline);
To update settings of an already created line, set new values to the Polyline object parameters: see the full list of available parameters in the Polyline description.

// Changing the coordinates of the line vertices
polyline.points = geopoints;

// Changing the line width
polyline.width = sdk.LogicalPixel(10);

// Changing the line color
polyline.color = sdk.Color(Colors.black.value);

// Changing the erased part
 polyline.erasedPart = 0.1;

// Changing the parameters of a dashed polyline
polyline.dashedPolylineOptions = sdk.DashedPolylineOptions();

// Changing the parameters of a gradient polyline
polyline.gradientPolylineOptions = sdk.GradientPolylineOptions();
Polygon
To draw a polygon on the map, create a Polygon object, specifying the required options in PolygonOptions, and pass it to the addObject() method of the object manager.

The coordinates for the polygon are specified as a two-dimensional list. The first sublist contains the coordinates of the vertices of the polygon. The other sublists are optional and can be specified to create a cutout inside the polygon (one sublist per polygonal cutout).

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

final sdk.GeoPoint point1 = sdk.GeoPoint(latitude: sdk.Latitude(55.7), longitude: sdk.Longitude(37.6));
final sdk.GeoPoint point2 = sdk.GeoPoint(latitude: sdk.Latitude(55.8), longitude: sdk.Longitude(37.7));
final sdk.GeoPoint point3 = sdk.GeoPoint(latitude: sdk.Latitude(55.9), longitude: sdk.Longitude(37.8));
final sdk.GeoPoint countor = <sdk.GeoPoint>[point1,point2,point3];
final sdk.GeoPoint point4 = sdk.GeoPoint(latitude: sdk.Latitude(55.7), longitude: sdk.Longitude(37.6));
final sdk.GeoPoint point5 = sdk.GeoPoint(latitude: sdk.Latitude(55.8), longitude: sdk.Longitude(37.7));
final sdk.GeoPoint point6 = sdk.GeoPoint(latitude: sdk.Latitude(55.9), longitude: sdk.Longitude(37.8));
final sdk.GeoPoint points = <sdk.GeoPoint>[point4,point5,point6];

final sdk.Polygon polygon = sdk.Polygon(
  sdk.PolygonOptions(
    contours: [countor,points],
    strokeWidth: sdk.LogicalPixel(5),
  ),
);
mapObjectManager.addObject(polygon);
To update settings of an already created polygon, set new values to the Polygon object parameters: see the full list of available parameters in the Polygon description.

// Changing the coordinates of the polygon vertices
polygon.contours = [contuor, points];

// Changing the polygon fill color
polygon.color = sdk.Color(Colors.black.value);

// Changing the polygon stroke width
polygon.strokeWidth = sdk.LogicalPixel(10);

// Changing the polygon stroke color
polygon.strokeColor = sdk.Color(Colors.black.value);
Circle
To draw a circle on the map, create a Circle object, specifying the required options in CircleOptions, and pass it to the addObject() method of the object manager.

// Configuring circle parameters
final circle = sdk.Circle(
  const sdk.CircleOptions(
    position: sdk.GeoPoint(latitude: sdk.Latitude(10),longitude: sdk.Longitude(10)),
    radius: sdk.Meter(10)
  )
);

// Creating and adding a circle to the map
mapObjectManager.addObject(circle);
To update settings of an already created polygon, set new values to the Circle object parameters: see the full list of available parameters in the Circle description.

// Changing the coordinated of a circle center
circle.position = sdk.GeoPoint(latitude: sdk.Latitude(55.752425),longitude: sdk.Longitude(37.613983));

// Changing the circle radius
circle.radius = sdk.Meter(10);

// Changing the circle fill color
circle.color = sdk.Color(Colors.black.value);

// Changing the circle stroke width
circle.strokeWidth = sdk.LogicalPixel(12);

// Changing the circle stroke color
circle.strokeColor = sdk.Color(Colors.black.value);
Adding multiple objects 
Do not add a collection of objects to the map using the addObject method in a loop for the entire collection. This leads to performance losses. To add a collection of objects, prepare the entire collection and add it using the addObjects method:

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

// Prepare a collection of objects
final List<sdk.Marker> markers = [];
final sdk.MarkerOptions markerOptions = sdk.MarkerOptions(
    <params>
  );

markers.add(sdk.Marker(markerOptions));

// Add the collection of objects to the map
mapObjectManager.addObjects(markers)
Clustering
Clustering is the visual grouping of closely located objects (markers) into a single cluster as you zoom out the map. The grouping occurs gradually: the lower the zoom level, the fewer clusters are formed. A cluster is displayed as a marker with a number indicating the count of objects in the cluster.

To add markers to the map in the clustering mode, create an object manager (MapObjectManager) using the MapObjectManager.withClustering() method and specify the following properties:

The map instance (map).
The minimum distance between markers in logical pixels at zoom levels at which clustering is active (logicalPixel).
The zoom level at which and above only individual markers are visible, without clusters (maxZoom).
The zoom level at which and below no new clusters are formed (minZoom).
A custom implementation of the SimpleClusterRenderer protocol, which is used to customize clusters in MapObjectManager.
import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

class SimpleClusterRendererImpl implements sdk.SimpleClusterRenderer {
  final sdk.Image image;
  int idx = 0;

  SimpleClusterRendererImpl({
    required this.image,
  });

  @override
  sdk.SimpleClusterOptions renderCluster(sdk.SimpleClusterObject cluster) {
    final int objectCount = cluster.objectCount;
    final sdk.MapDirection? iconMapDirection =
        objectCount < 5 ? const sdk.MapDirection(45) : null;
    idx += 1;

    const double baseSize = 30.0;
    final double sizeMultiplier = 1.0 + (objectCount / 50.0);
    final double iconSize = min(baseSize * sizeMultiplier, 100);

    return sdk.SimpleClusterOptions(
      icon: image,
      iconMapDirection: iconMapDirection,
      text: objectCount.toString(),
      iconWidth: sdk.LogicalPixel(iconSize),
      userData: idx,
      zIndex: const sdk.ZIndex(1),
    );
  }
}

clusterRenderer ??= SimpleClusterRendererImpl(
  image: loader.loadSVGFromAsset("assets/icons/bridge.svg"),
);

mapObjectManager = sdk.MapObjectManager.withClustering(
  map,
  const sdk.LogicalPixel(80.0),
  const sdk.Zoom(19.0),
  const sdk.Zoom(8.0),
  clusterRenderer
);
Once an object manager with clustering is created, you can add markers as usual using addObject() or addObjects().

Generalization
Generalization is the visual grouping of closely located objects (markers) such that, as you zoom out the map, a single "key" object is displayed instead of several markers. The grouping occurs gradually: the lower the zoom level, the fewer groups are formed.

To add markers to the map in the generalization mode, create an object manager (MapObjectManager) using the MapObjectManager.withGeneralization() method and specify the following properties:

The map instance (map).
The minimum distance between markers in logical pixels at zoom levels at which generalization is active (logicalPixel).
The zoom level at which and above only individual markers are visible, without groups (maxZoom).
The zoom level at which and below no new groups are formed (minZoom).
import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

mapObjectManager = sdk.MapObjectManager.withGeneralization(
  map,
  const sdk.LogicalPixel(80.0),
  const sdk.Zoom(19.0),
  const sdk.Zoom(8.0)
);
Once an object manager with generalization is created, you can add markers as usual using addObject() or addObjects().

Styling objects
You can configure a complex style for a dynamic object using the Style editor. For example, configure the maximum and minimum zoom level on which the object must be displayed.

Create a style layer for an object:

Open the Style editor.

Open the required style or create a new one.

In the Layers section, click Add a layer icon.

Select the layer type depending on the object type. For the current task, only Polygon, Line, and Point types are supported. See more about layers in the Layer types for the Mobile SDK article.

On the Data tab, scroll down and select JSON — add manually.

Add the db_sublayer attribute with a unique layer identifier (for example, my_object_layer) by inserting the following code into the text field:

["match", ["get", "db_sublayer"], ["my_object_layer"], true, false]
This identifier will be later used in the code to refer to the style layer.

Example of editing JSON
Configure other style parameters on corresponding tabs.

Export and connect the style.

Create a dynamic object using GeometryMapObjectBuilder and specify the identifier of the created style layer in the setObjectAttribute() method. For example, to add an object of the point type:

final geometryObject = sdk.GeometryMapObjectBuilder()
  ..setGeometry(sdk.PointGeometry(point)) // Point geometry
  ..setObjectAttribute('db_sublayer', sdk.AttributeValue.string('my_object_layer'))
  ..createObject();   // Creating an object
To display the object on the map, add it to the data source:

Create a source:

final geometrySource = sdk.GeometryMapObjectSourceBuilder(sdkContext).createSource();
Add the source to the map:

map.addSource(geometrySource);
Add the created object to the source:

geometrySource.addObject(geometryObject);
Selecting objects 
Configuring styles
To make objects on the map react to selection, configure the styles to use different layer looks using the Add state dependency function for all required properties (icon, font, color, and others).


To configure the properties of the selected object, go to the Selected state tab:


Highlight selected objects on tap 
First, get information about the objects falling into the tap region using the getRenderedObjects() method, as in the example Getting objects using screen coordinates.

To highlight objects, call the setHighlighted() method, which takes a list of IDs from the variable objects directory DgisObjectId. Within the getRenderedObjects() method, you can get all the data required to use this method, e.g., a data source of objects and their IDs:

mapWidgetController
    .addObjectTappedCallback((sdk.RenderedObjectInfo info) async {
  // Get the closest object to the tap spot inside the specified radius
  final sdk.RenderedObject obj = info.item;

  // In this example, we want to search for information about the selected object in the directory.
  // To do this, make sure that the type of this object can be found.
  if (obj.source is sdk.DgisSource && obj.item is sdk.DgisMapObject) {
    final source = obj.source as sdk.DgisSource;

    // Search
    final foundObject =
        await sdk.SearchManager.createOnlineManager(sdkContext)
            .searchByDirectoryObjectId((obj.item as sdk.DgisMapObject).id)
            .value;

    final entranceIds =
        foundObject?.entrances.map((entrance) => entrance.id).toList() ??
            List.empty();

    // Remove the highlight from the previously selected objects
    source
      ..setHighlighted(source.highlightedObjects, false)
      // Highlight the required objects and entrances
      ..setHighlighted(entranceIds, true);
  }
});
Controlling the camera 
You can control the camera by accessing the map.camera property of the Camera object.

Changing camera position
You can change the position of the camera by calling the move() method, which initiates a flight animation. Specify parameters:

position - new camera position (coordinates and zoom level). Additionally, you can specify the camera tilt and rotation (CameraPosition).
time - flight duration in seconds (Duration).
animationType - animation type (CameraAnimationType).
The move() function returns a Future object, which you can use to process the event of the animation stop.

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

final sdk.Map map = mapWidgetController.getMapAsync((map) {
  sdkMap = map;
});
final sdk.CameraPosition cameraPosition = const sdk.CameraPosition(
    point: sdk.GeoPoint(
      latitude: sdk.Latitude(55.759909),
      longitude: sdk.Longitude(37.618806),
    ),
    zoom: sdk.Zoom(15),
    tilt: sdk.Tilt(15),
    bearing: sdk.Bearing(115),
  );

map.camera.moveToCameraPosition(
    position,
    const Duration(seconds: 3),
    sdk.CameraAnimationType.linear,
  );
For more precise control over the flight animation, you can use a flight controller, which will determine the camera position at any given moment. To do this, implement the CameraMoveController interface and pass the created object to the move() method instead of the parameters described previously.

Getting camera state
You can obtain the current state of the camera (i.e., whether the camera is currently in flight) using the state property. See a CameraState object for a list of possible camera states.

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

final sdk.CameraState currentState = map.camera.state;
You can subscribe to changes in camera state using the stateChannel property:

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

map.camera.stateChannel.listen((sdk.CameraState cameraState) {
  // Processing camera status changes
});
Getting camera position
You can obtain the current position of the camera using the position property. See a CameraPosition object.

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

final sdk.CameraPosition currentPosition = sdkMap.camera.position;
You can subscribe to changes in camera position (and the camera tilt and rotation) using the positionChannel property:

sdkMap.camera.positionChannel.listen((position) {
  // Processing camera position changes
});
Calculating camera position
To display an object or a group of objects on the map, you can use the calcPositionForObjects or the calcPositionForGeometry method to calculate camera position:

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

// To "see" two markers on the map:

// Creating a geometry that covers both objects
final List<sdk.SimpleMapObject> objects = [marker1, marker2, marker3];
// Calculating the required position
final position = sdk.calcPositionForObjects(camera, objects, styleZoomToTiltRelation, screenArea, tilt, bearing, size)

// Using the calculated position
map.camera.moveToCameraPosition(position)
The example above returns a result similar to:


The markers are cut in half, because the method does not have any information about objects, only geometry. In this example, the marker is in its center. The method calculates the position to embed marker centers in the active area. The active area is shown as a red rectangle along the screen edges. To display markers in full, you can set the active area.

For example, set paddings from the top and bottom of the screen:

// Setting top and bottom paddings so that markers are displayed in full
sdkCamera.padding = sdk.Padding(top: 100, bottom: 100);

final position = sdk.calcPositionForObjects(camera, objects, styleZoomToTiltRelation, screenArea, tilt, bearing, size);
map.camera.moveToCameraPosition(position);
Result:


You can also set specific parameters for position calculation only. For example, you can set paddings only inside the position calculation method and get the same result.

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

final sdk.Geometry geometry = sdk.ComplexGeometry([sdk.PointGeometry(point1), sdk.PointGeometry(point2),])
// Setting an active area only for the position calculation
val position = sdk.calcPositionForGeometry(map.camera, geometry, styleZoomToTiltRelation, sdk.Padding({top:100, bottom:100}), tilt, bearing, size,)
map.camera.move(position)
Result:


You can see that the active area is not changed, but the markers are fully embedded. This approach may cause unexpected behavior, because the camera position specifies a geocoordinate that must be within the camera position spot (a red circle in the screen center). Parameters like padding, positionPoint, and size impact the location of this spot.

If parameters that shift the camera position spot are passed to a method during the position calculation, the result may lead to unexpected behavior. For example, if you set an asymmetric active area, the picture can shift a lot.

Example of setting the same position for different paddings:


The easiest solution is to pass all required settings to the camera and use only the camera and geometry to calculate position. If you use additional parameters that are not passed to the camera, edit the result to shift the picture in the right direction.

Configuring camera position point and camera viewpoint
You can control the map display on the screen, for example, change the size of the map viewport, while keeping the view position. To do this, use screen points: the camera position point BaseCamera.positionPoint and the camera viewpoint BaseCamera.viewPoint.


The camera position point (BaseCamera.positionPoint) is the screen point to which the camera is anchored with the set paddings (BaseCamera.padding). The point is set relative to the map viewport:

const cameraPositionPoint = sdk.CameraPositionPoint(x: 0.5, y: 0.5);
map.camera.positionPoint = cameraPositionPoint;
When the camera position point changes, the map viewport changes and the observation point CameraPosition.Point shifts. It is a terrain point in geographic coordinates that is located at the camera position point. The tilt angle CameraPosition.Tilt and the camera rotation angle CameraPosition.Bearing do not change:

 


The camera viewpoint (BaseCamera.viewPoint) is the screen point the camera is looking at. The point is set relative to the map viewport:

const cameraViewPoint = sdk.CameraViewPoint(x: 0.5, y: 0.5);
map.camera.viewPoint = cameraViewPoint;
When the camera viewpoint changes, the direction of view relative to the observation point changes. The observation point CameraPosition.Point does not shift. Also, the tilt angle CameraPosition.Tilt and the camera rotation angle CameraPosition.Bearing do not change:


visibleArea и visibleRect
Camera has two properties that both describe the geometry of the visible area but in different ways. visibleRect has a GeoRect type and is always a rectangle. visibleArea is an arbitrary geometry. You can see the difference easily with examples of different camera tilt angles (relative to the map):

With 45° tilt, visibleRect and visibleArea are not equal: in this case, visibleRect is larger because it is a rectangle containing visibleArea.

visibleArea is displayed in blue, visibleRect – in red.


With 0° tilt, visibleArea и visibleRect overlap, as you can see from the color change.


Detecting if an object falls into the camera coverage area
Using the visibleArea property, you can get the map area covered by the camera as a Geometry. Using the intersects() method, you can get the intersection of the camera coverage area with the required geometry:

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

camera.visibleArea.intersects(geometry)
Traffic jams on the map 
To display the traffic jams layer on the map, create a TrafficSource and pass it to the addSource() method of the map.

final sdk.TrafficSource trafficSource = sdk.TrafficSource(sdkContext);
map.addSource(trafficSource);
Road events on the map 
You can configure the display of road events from 2GIS data on the map, as well as add your own events.

Displaying events on the map
To display the road events layer on the map, create a data source RoadEventSource and add it to the map using the addSource() method of the map:

final sdk.RoadEventSource roadEventSource = sdk.RoadEventSource(sdkContext);
map?.addSource(roadEventSource);
To remove the created data source and all associated objects, call the removeSource() method of the map:

map?.removeSource(roadEventSource);
Adding an event
You can add your own road event to the map, which will be visible to all 2GIS map users.

Note

You can place an event on the map only within a 2 km radius of your current location.

Create an instance of the object manager RoadEventManager:

final sdk.RoadEventManager roadEventManager = sdk.RoadEventManager(sdkContext);
Add an event of one of the types below (each type has its own icon on the map):

Car accident. Call the createAccident() method and specify the event coordinates (GeoPoint), affected lanes (Lane), and a text description of the event:

final accidentLocation = sdk.GeoPoint(
  latitude: sdk.Latitude(55.751244),
  longitude: sdk.Longitude(37.618423)
);
final accidentLanes = sdk.LaneEnumSet.of([sdk.Lane.left, sdk.Lane.center]); // left and center lanes are affected

final accidentOperation = roadEventManager.createAccident(
  accidentLocation,
  accidentLanes,
  "Accident on the left lane"
);

// Handling the result
accidentOperation.value.then((result) {
  if (result.isEvent) {
    print("Accident event successfully created! ID: ${result.asEvent?.id}");
  } else if (result.isError) {
    print("Error creating the event: ${result.asError}");
  }
});
Traffic camera. Call the createCamera() method and specify the event coordinates (GeoPoint) and a text description:

final cameraLocation = sdk.GeoPoint(
  latitude: sdk.Latitude(55.752220),
  longitude: sdk.Longitude(37.615560)
);

final cameraOperation = roadEventManager.createCamera(
  cameraLocation,
  "Speed control camera"
);

// Handling the result
cameraOperation.value.then((result) {
  if (result.isEvent) {
    print("Camera event successfully created! ID: ${result.asEvent?.id}");
  } else if (result.isError) {
    print("Error creating the event: ${result.asError}");
  }
});
Road closure. Call the createRoadRestriction() method and specify the event coordinates (GeoPoint) and a text description:

final restrictionLocation = sdk.GeoPoint(
  latitude: sdk.Latitude(55.753930),
  longitude: sdk.Longitude(37.620795)
);

final restrictionOperation = roadEventManager.createRoadRestriction(
  restrictionLocation,
  "Road closed for the festival"
);

// Handling the result
restrictionOperation.value.then((result) {
  if (result.isEvent) {
    print("Road restriction event successfully created! ID: ${result.asEvent?.id}");
  } else if (result.isError) {
    print("Error creating the event: ${result.asError}");
  }
});
Roadworks. Call the createRoadWorks() method and specify the event coordinates (GeoPoint), affected lanes (Lane), and a text description of the event:

final roadWorksLocation = sdk.GeoPoint(
  latitude: sdk.Latitude(55.754800),
  longitude: sdk.Longitude(37.621000)
);
final roadWorksLanes = sdk.LaneEnumSet.of([sdk.Lane.right]); // right lane is affected

final roadWorksOperation = roadEventManager.createRoadWorks(
  roadWorksLocation,
  roadWorksLanes,
  "Road surface repair"
);

// Handling the result
roadWorksOperation.value.then((result) {
  if (result.isEvent) {
    print("Road works event successfully created! ID: ${result.asEvent?.id}");
  } else if (result.isError) {
    print("Error creating the event: ${result.asError}");
  }
});
Comment. Call the createComment() method and specify the event coordinates (GeoPoint) and a text description:

final commentLocation = sdk.GeoPoint(
  latitude: sdk.Latitude(55.755000),
  longitude: sdk.Longitude(37.622000)
);

final commentOperation = roadEventManager.createComment(
  commentLocation,
  "Caution, icy road!"
);

// Handling the result
commentOperation.value.then((result) {
  if (result.isEvent) {
    print("Comment successfully created! ID: ${result.asEvent?.id}");
  } else if (result.isError) {
    print("Error creating the event: ${result.asError}");
  }
});
Other event. Call the createOther() method and specify the event coordinates (GeoPoint), affected lanes (Lane), and a text description of the event:

final otherLocation = sdk.GeoPoint(
  latitude: sdk.Latitude(55.756000),
  longitude: sdk.Longitude(37.623000)
);
final otherLanes = sdk.LaneEnumSet.of([sdk.Lane.center, sdk.Lane.right]); // center and right lanes are affected

final otherOperation = roadEventManager.createOther(
  otherLocation,
  otherLanes,
  "Obstacle on the road"
);

// Handling the result
otherOperation.value.then((result) {
  if (result.isEvent) {
    print("Other event successfully created! ID: ${result.asEvent?.id}");
  } else if (result.isError) {
    print("Error creating the event: ${result.asError}");
  }
});
Getting objects using screen coordinates 
To get information about map objects using pixel coordinates, you can call the getRenderedObjects() method of the map, specifying pixel coordinates and a radius in screen millimeters (not more than 30). This method returns a deferred result containing information about all the found objects within the specified radius on the visible area of the map (a List<RenderedObjectInfo> list).

An example of a function that takes tap coordinates and passes them to the getRenderedObjects() method:

import 'package:dgis_mobile_sdk_map/dgis.dart' as sdk;

map.getRenderedObjects(sdk.ScreenPoint(), sdk.ScreenDistance(30.0)).then((List<sdk.RenderedObjectInfo> info) {
  // Callback
});
In addition to using it directly, you can set a callback for tap (addObjectTappedCallback) or long tap (addObjectLongTouchCallback) in the MapWidgetController, as you can see in the example with highlighting objects on map tap.

Working with map control gestures 
You can customize working wth gestures in one of the following ways:

Configure existing gestures.
Implement your own mechanism of gesture recognition.
Configuring gestures
You can control the map using the following standard gestures:

Shift the map in any direction with one finger.
Shift the map in any direction with multiple fingers.
Rotate the map with two fingers.
Scale the map with two fingers (pinch).
Zoom the map in by double-tapping.
Zoom the map out with two fingers.
Scale the map with the tap-tap-swipe gesture sequence using one finger.
Tilt the map by swiping up or down with two fingers.
By default, all gestures are enabled. You can disable selected gestures using the GestureManager.

You can get the GestureManager directly from the MapWidgetController:

mapWidgetController.getMapAsync((map) {
  gestureManager = mapWidgetController.gestureManager;
})
To manage gestures, use the following methods:

enableGesture for gestures activation;
disableGesture for gestures deactivation;
gestureEnabled for checking whether a gesture is enabled or not.
To change the settings or get information about multiple gestures at once, use the enabledGestures property.

A specific gesture is set using Gesture properties. The scaling property is responsible for the entire group of map scaling gestures. You cannot disable these gestures one by one.

Some gestures have specific lists of settings:

MultiTouchShiftSettings for shifting the map with multiple fingers.
RotationSettings for rotation.
ScalingSettings for scaling.
TiltSettings for tilting.
For more information about settings, see the documentation. Objects of these settings are accessible via GestureManager.

You can also configure the behavior of map scaling and rotation. You can specify the point relative to which map rotation and scaling will be performed. By default, these operations are done relative to the "center of mass" of the finger placement points. You can change this behavior using the EventsProcessingSettings setting. To implement the setting, use the setSettingsAboutMapPositionPoint() method.

To control simultaneous activation of multiple gestures, use the setMutuallyExclusiveGestures method.