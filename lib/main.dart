import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';// Start timing ASAP

Future<void> main() async {
  final Stopwatch launchStopwatch = Stopwatch()..start(); 
  /*await dotenv.load(fileName: ".env");
  final String apiKey;
  apiKey= dotenv.env['supbase_key'] ?? 'default_key';*/
  await Supabase.initialize(
    url: 'https://mdkqfbuaykfzufpsittf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ka3FmYnVheWtmenVmcHNpdHRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1NjQ2MTMsImV4cCI6MjA1ODE0MDYxM30.wgbFWxh7-BYQfkFmh15OerywCV8jxHlhxp7CDesfgeM',
    
  );
    var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://api-new-898298453090.europe-west2.run.app/warmup'),
  );
  //var response = await request.send();

  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();//creates camera for use throughout the app
  final firstCamera = cameras.first;
   final prefs = await SharedPreferences.getInstance();
  final initialGender = prefs.getString('last_selected_gender') ?? '';
  await Future.delayed(Duration(seconds: 1));
  
  runApp(
     ChangeNotifierProvider(
      create: (context) => GenderProvider(initialGender),
      child: MyApp(camera: firstCamera),
    )
    );
}


class GenderProvider with ChangeNotifier {
  GenderProvider(this._selectedGender);//sets gender as the gender passed in
  String _selectedGender = '';

  String get selectedGender => _selectedGender;
  static const String _prefsKey = 'last_selected_gender';
  

  Future<void> _loadGender() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedGender = prefs.getString(_prefsKey) ?? '';
    notifyListeners(); 
  }//loads the last used gender and sets it as selected gender

  Future<void> setGender(String gender) async {
    _selectedGender = gender;
    notifyListeners();
    
    
    final prefs = await SharedPreferences.getInstance();//stores between instances
    await prefs.setString(_prefsKey, gender);
  }
}

// Get a reference your Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({super.key,required this.camera});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
 
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
      ),
      home: MainScreen(camera: camera,)
    );
  }
}
class MainScreen extends StatefulWidget {
  final Widget? overridePage;
  final CameraDescription camera;
  final int initialIndex; // <-- new

  const MainScreen({
    Key? key,
    this.overridePage,
    required this.camera,
    this.initialIndex = 0, // <-- default to 0 (Home)
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

@override
void initState() {
  super.initState();
  _selectedIndex = widget.initialIndex;
}
  // List of pages to navigate to

  List<Widget> get _defaultPages => <Widget>[
    MyHomePage(title: 'Get your clothes reccomendation', camera: widget.camera),
    FavoriteOutfitsPage(),
    SettingsPage(),
  ];

void _onItemTapped(int index) {
  if (widget.overridePage != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          camera: widget.camera,
          initialIndex: index, 
        ),
      ),
    );
  } else {
    setState(() {
      _selectedIndex = index;
    });
  }
}

   @override
  Widget build(BuildContext context) {
    // Use overridePage if provided, otherwise show selected page
    final currentPage = widget.overridePage ?? _defaultPages[_selectedIndex];

    return Scaffold(
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title,required this.camera});

  final String title;
  final CameraDescription camera;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;
  bool _showCamera = false;
  List text = ["default"];
  var responseData;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras[0], // Use the first camera (usually back camera)
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null){
         final imageTemp = File(image.path);
      setState(() {
        this.image = imageTemp;
      });
      }
    } on Exception catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<void> takePicture() async {
    if (!_isCameraReady) return;

    try {
      final image = await _controller.takePicture();
      setState(() {
        this.image = File(image.path);
      });
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  Future<void> getCategory() async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://api-new-898298453090.europe-west2.run.app/predict'),
  );

  // Add the file to the request
  
    final imageFile = image!;
    request.files.add(
        await http.MultipartFile.fromPath(
      'file', // Field name for the file upload
      imageFile.path, // Path to the image file
    ),
  );


  // Send the request
  var response = await request.send();

  // Get the response
  if (response.statusCode == 200) {
    final responseString = await response.stream.bytesToString();
    responseData = jsonDecode(responseString);
    print(responseData);
  } else {
    print('Request failed with status: ${response.statusCode}');
  }
}

  Future<void> _processAndNavigate() async {
    if (image != null) {
      await getCategory();
      if (responseData != null) {
        print("ready to go to next page");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MySearchPage(prediction: responseData),
          ),
        );
      }
    }
  }



   @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
  title: Text(widget.title),
),
     body: SingleChildScrollView(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: MediaQuery.of(context).size.height,
    ),
    child: IntrinsicHeight(
  child:Center(
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 60),
            SizedBox(
            width: 250,
            height: 100,  
            child:MaterialButton(
              color: Theme.of(context).colorScheme.primaryContainer,
               child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
               Text(
                  "Pick Image from Gallery",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer, 
                      fontWeight: FontWeight.bold
                  )
              ),
               SizedBox(height: 8), 
        Icon(
          Icons.photo_library,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ],
               ),
              onPressed: () async {
                await pickImage();
                if (image != null) {
                  await getCategory();
                  if (responseData != null) {
                    print("ready to go to next page");
                    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MainScreen(camera:widget.camera, overridePage:MySearchPage(prediction: responseData)),
  ),
);
                  }
                }
              }
            ),
            ),
            SizedBox(height: 60), // space between buttons / preview

            
            SizedBox(
            width: 250,
            height: 100,
            child:MaterialButton(
              color: Theme.of(context).colorScheme.primaryContainer,
               child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
              Text(
                  _showCamera ? "Take Picture" : "Open Camera",//displays take picture is _showCamera is true or Open camera is false
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer, 
                      fontWeight: FontWeight.bold
                  )
              ),
               SizedBox(height: 8), 
        Icon(
          _showCamera ? Icons.camera : Icons.camera_alt_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ],
    ),
              
              onPressed: () async {
                if (!_showCamera) {//if show camera is false then sets it to true
                  setState(() => _showCamera = true);
                  return;//return stops logic reaching takePicture
                }
                
                try {
                  await takePicture();
                  if (image != null) {
                    await getCategory();
                    if (responseData != null) {
                      print("ready to go to next page");
                     Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MainScreen(camera:widget.camera, overridePage:MySearchPage(prediction: responseData)),
  ),
);
                    }
                  }
                } catch (e) {
                  print(e);
                }
              },
            ),

            ), 
            SizedBox(height: 60), // space between buttons / preview


             if (_showCamera && _isCameraReady)
              CameraPreview(_controller),
            
          ],
        ),
      ),
      )
  )
     )
    );
  }
}
class MySearchPage extends StatefulWidget {
  final dynamic prediction;
  const MySearchPage({super.key, required this.prediction});




  @override
  State<MySearchPage> createState() => _MySearchPageState();
}
  class _MySearchPageState extends State<MySearchPage> {
  File? image;
  List text=["default"];
  bool isLoading = true;
  Set<String> favorites = Set();
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call the Query function after the widget is inserted into the widget tree
    // and after context-dependent data is available.
    Query();
  }
  _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList('favorites')?.toSet() ?? Set();
    });
  }

  // Save the favorites to SharedPreferences
  _saveFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorites', favorites.toList());
  }

Future Query() async {
  final category = widget.prediction[0] as String;
  print(widget.prediction[0]);
  final attributes = (widget.prediction[1] as List<dynamic>).cast<String>();
  if (Provider.of<GenderProvider>(context).selectedGender=="Masculine"){
    try {
    final response = await supabase.rpc('get_filtered_outfits', params: {
  'p_category': category.trim().toLowerCase(),
  'p_attributes': attributes.map((a) => a.trim().toLowerCase()).toList(),
  'p_gender': 1
}).select();
    print("Success! Found ${response} matching outfits");
    
    setState(() {
      text = response.map((outfit) => outfit['image']).toList();//turns the returned image names into a list for display
      isLoading = false;//sets is loading to false so page can be displayed now query is complete
    });
  } catch (e) {
    print("Query error: ${e.toString()}");
    setState(() {
      text = ["Error loading results"];
      isLoading = false;
    });
  }

  }
  else{
    try {
    final response = await supabase.rpc('get_filtered_outfits', params: {
      'p_category': category,
      'p_attributes': attributes,
      'p_gender':2
    });
    print("Success! Found ${response} matching outfits");
    
    setState(() {
      text = response.map((outfit) => outfit['image']).toList();
      isLoading = false;
    });
  } catch (e) {
    print("Query error: ${e.toString()}");
    setState(() {
      text = ["Error loading results"];
      isLoading = false;
    });
  }
  }

   
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : text.isEmpty
              ? Center(child: Text('No results found'))
              : ListView.builder(
                  itemCount: text.length,
                  itemBuilder: (context, index) {
                    String imageName = text[index];
                    bool isFavorite = favorites.contains(imageName);

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFavorite) {
                                favorites.remove(imageName);
                              } else {
                                favorites.add(imageName);
                              }
                              _saveFavorites();  // Save favorites after modification
                            });
                          },
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.asset(
                                'assets/clothing_images/$imageName',
                                width: 250,
                                height: 250,
                                fit: BoxFit.contain,
                              ),
                              Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                                size: 30.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

  
  class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return Container();
  }
}
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Provider.of<GenderProvider>(context).selectedGender=="Masculine"
                 ? Theme.of(context).colorScheme.inversePrimary
                 : Theme.of(context).colorScheme.surface),
  onPressed: () {
    Provider.of<GenderProvider>(context, listen: false).setGender("Masculine");
  },
  child: Text("Masculine"),
),
ElevatedButton(
  style: ElevatedButton.styleFrom(
                backgroundColor: Provider.of<GenderProvider>(context).selectedGender=="Feminine"
                 ? Theme.of(context).colorScheme.inversePrimary
                 : Theme.of(context).colorScheme.surface),
  onPressed: () {
    Provider.of<GenderProvider>(context, listen: false).setGender("Feminine");
  },
  child: Text("Feminine"),
),
          ],
        ),
      ),
    );
  }
}
class FavoriteOutfitsPage extends StatefulWidget {
  @override
  _FavoriteOutfitsPageState createState() => _FavoriteOutfitsPageState();
}

class _FavoriteOutfitsPageState extends State<FavoriteOutfitsPage> {
  Set<String> favorites = Set();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // Load favorites from SharedPreferences
  _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList('favorites')?.toSet() ?? Set();
    });
  }

  // Save the favorites to SharedPreferences
  _saveFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorites', favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Outfits'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: favorites.isEmpty
          ? Center(child: Text('No favorites added yet!'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                String imageName = favorites.elementAt(index);
                bool isFavorite = favorites.contains(imageName);

                
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFavorite) {
                                favorites.remove(imageName);
                              } else {
                                favorites.add(imageName);
                              }
                              _saveFavorites();  // Save favorites after modification
                            });
                          },
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.asset(
                                'assets/clothing_images/$imageName',
                                width: 250,
                                height: 250,
                                fit: BoxFit.contain,
                              ),
                              Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                                size: 30.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
              },
            ),
    );
  }
}