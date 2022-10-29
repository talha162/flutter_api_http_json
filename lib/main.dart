import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PostsList(),
    );
  }
}

class HTTPHelper {
  //--Fetching all items
  Future<List<Map>> fetchItems() async {
    List<Map> items = [];

    //--Get the data from the API
    http.Response response =
    await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));

    if (response.statusCode == 200) {
      //get the data from the response
      String jsonString = response.body;
      //Convert to List<Map>
      List data = jsonDecode(jsonString);
      items= data.cast<Map>();
    }

    return items;
  }

  //--Fetch details of one item
  Future<Map> getItem(itemId) async {
    Map item = {};

    //Get the item from the API
    http.Response response = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/posts/$itemId'));

    if (response.statusCode == 200) {
      //get the data from the response
      String jsonString = response.body;
      //Convert to List<Map>
      item = jsonDecode(jsonString);
    }

    return item;
  }

  //-- Add a new item
  Future<bool> addItem(Map data) async {
    bool status = false;

    //Add the item to the database, call the API
    http.Response response = await http
        .post(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
        body: jsonEncode(data),
        headers: {
          'Content-type':'application/json'
        }
    );

    if(response.statusCode==201)
    {
      status=response.body.isNotEmpty;
    }

    return status;
  }

//-- Update an item
  Future<bool> updateItem(Map data, String itemId) async {
    bool status = false;

    //Update the item, call the API
    http.Response response = await http
        .put(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/$itemId'),
        body: jsonEncode(data),
        headers: {
          'Content-type':'application/json'
        }
    );

    if(response.statusCode==200)
    {
      status=response.body.isNotEmpty;
    }

    return status;
  }

  //--Delete an item
  Future<bool> deleteItem(String itemId) async {
    bool status = false;

    //Delete the item from the Database
    http.Response response=await http.delete(Uri.parse('https://jsonplaceholder.typicode.com/posts/$itemId'),);

    if(response.statusCode==200)
    {
      status=true;
    }

    return status;
  }
}



class PostsList extends StatelessWidget {
  PostsList({Key? key}) : super(key: key);

  Future<List<Map>> _futurePosts = HTTPHelper().fetchItems();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddPost()));

        },
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map>>(
        future: _futurePosts,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          //Check for errors
          if (snapshot.hasError) {
            return Center(child: Text('Some error occurred ${snapshot.error}'));
          }
          //Has data arrived
          if (snapshot.hasData) {
            List<Map> posts = snapshot.data;

            return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  Map thisItem = posts[index];
                  return ListTile(
                    title: Text('${thisItem['title']}'),
                    subtitle: Text('${thisItem['body']}'),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PostDetails(thisItem['id'].toString())));
                    },
                  );
                });
          }

          //Display a loader
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class PostDetails extends StatelessWidget {
  PostDetails(this.itemId, {Key? key}) : super(key: key) {
    _futurePost = HTTPHelper().getItem(itemId);
  }

  String itemId;
  late Future<Map> _futurePost;
  late Map post;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        actions: [
          IconButton(onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditPost(post)));
          }, icon: Icon(Icons.edit)),
          IconButton(onPressed: () async{
            //Delete
            bool deleted=await HTTPHelper().deleteItem(itemId);

            if(deleted)
            {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Post deleted')));
            }
            else
            {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Failed to delete')));
            }
          }, icon: Icon(Icons.delete)),
        ],
      ),
      body: FutureBuilder<Map>(
        future: _futurePost,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Some error occurred ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            post = snapshot.data!;

            return Column(
              children: [
                Text(
                  '${post['title']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${post['body']}'),
              ],
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
class AddPost extends StatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  TextEditingController _controllerTitle = TextEditingController();
  TextEditingController _controllerBody = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(
                    hintText: 'Add a title'
                ),
                controller: _controllerTitle,
              ),
              TextFormField(
                decoration: InputDecoration(
                    hintText: 'Add a body'
                ),
                controller: _controllerBody,
                maxLines: 5,
              ),
              ElevatedButton(
                  onPressed: () async {
                    Map<String, String> dataToUpdate = {
                      'title': _controllerTitle.text,
                      'body': _controllerBody.text,
                    };

                    bool status = await HTTPHelper()
                        .addItem(dataToUpdate);

                    if (status) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Post added')));
                    }
                    else
                    {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Failed to add the post')));
                    }
                  },
                  child: Text('Submit'))
            ],
          ),
        ),
      ),
    );
  }
}

class EditPost extends StatefulWidget {
  EditPost(this.post, {Key? key}) : super(key: key);
  Map post;

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  TextEditingController _controllerTitle = TextEditingController();
  TextEditingController _controllerBody = TextEditingController();

  initState() {
    super.initState();
    _controllerTitle.text = widget.post['title'];
    _controllerBody.text = widget.post['body'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              TextFormField(
                controller: _controllerTitle,
              ),
              TextFormField(
                controller: _controllerBody,
                maxLines: 5,
              ),
              ElevatedButton(
                  onPressed: () async {
                    Map<String, String> dataToUpdate = {
                      'title': _controllerTitle.text,
                      'body': _controllerBody.text,
                    };

                    bool status = await HTTPHelper()
                        .updateItem(dataToUpdate, widget.post['id'].toString());

                    if (status) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Post updated')));
                    }
                    else
                    {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Failed to update the post')));
                    }
                  },
                  child: Text('Submit'))
            ],
          ),
        ),
      ),
    );
  }
}
