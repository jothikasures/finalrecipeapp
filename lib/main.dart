import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Future<Database> database = openDatabase(
    join(await getDatabasesPath(), 'recipe_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE recipes(id INTEGER PRIMARY KEY, title TEXT, ingredients TEXT, instructions TEXT)',
      );
    },
    version: 1,
  );

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final Future<Database> database;

  const MyApp({required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RecipeListScreen(database: database),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RecipeListScreen extends StatefulWidget {
  final Future<Database> database;

  RecipeListScreen({required this.database});

  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late Future<List<Map<String, dynamic>>> recipes;

  @override
  void initState() {
    super.initState();
    refreshRecipes();
  }

  Future<void> refreshRecipes() async {
    setState(() {
      recipes = getRecipes();
    });
  }

  Future<List<Map<String, dynamic>>> getRecipes() async {
    final Database db = await widget.database;
    return await db.query('recipes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu),
            SizedBox(width: 10,),
            Text('Recipes Corner',
            style: TextStyle(fontSize: 24,
            fontWeight: FontWeight.bold),),

        ],
        ),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Center(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: recipes,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }

            final List<Map<String, dynamic>> recipes = snapshot.data!;

            return ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return ListTile(
                  title: Text(recipe['title'],
                  style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.normal),),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipe: recipe, database: widget.database),
                      ),
                    ).then((_) {
                      refreshRecipes();
                    });
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRecipeScreen(database: widget.database),
            ),
          ).then((_) {
            refreshRecipes();
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final Future<Database> database;

  RecipeDetailScreen({required this.recipe, required this.database});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['title'],
        style: TextStyle(fontSize: 20,
        fontWeight: FontWeight.bold)),
      ),
      backgroundColor: Colors.lightBlueAccent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(Icons.title, 'Title', recipe['title']),
            _buildRow(Icons.shopping_basket, 'Ingredients', recipe['ingredients']),
            _buildRow(Icons.list_alt, 'Instructions', recipe['instructions']),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditRecipeScreen(recipe: recipe, database: database),
                      ),
                    ).then((_) {
                      Navigator.pop(context);
                    });
                  },
                  child: Text('Edit'),
                ),
                ElevatedButton(
                  onPressed: () {
                    deleteRecipe(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white70),
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String text) {
    return Row(
      children: [
        Icon(icon),
        SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 5),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }

  void deleteRecipe(BuildContext context) async {
    final Database db = await database;
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [recipe['id']],
    );
    Navigator.pop(context);
  }
}




class AddRecipeScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController ingredientsController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  final Future<Database> database;

  AddRecipeScreen({required this.database});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          children: [
            Text('Add Recipes',
              style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 25),)
          ],
        ),

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title',),
            ),
            TextField(
              controller: ingredientsController,
              decoration: InputDecoration(labelText: 'Ingredients'),
            ),
            TextField(
              controller: instructionsController,
              decoration: InputDecoration(labelText: 'Instructions'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                addRecipe(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void addRecipe(BuildContext context) async {
    final Database db = await database;
    await db.insert(
      'recipes',
      {
        'title': titleController.text,
        'ingredients': ingredientsController.text,
        'instructions': instructionsController.text,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Navigator.pop(context);
  }
}

class EditRecipeScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController ingredientsController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  final Future<Database> database;

  EditRecipeScreen({required this.recipe, required this.database}) {
    titleController.text = recipe['title'];
    ingredientsController.text = recipe['ingredients'];
    instructionsController.text = recipe['instructions'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title',),
            ),
            TextField(
              controller: ingredientsController,
              decoration: InputDecoration(labelText: 'Ingredients'),
            ),
            TextField(
              controller: instructionsController,
              decoration: InputDecoration(labelText: 'Instructions'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                updateRecipe(context);
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void updateRecipe(BuildContext context) async {
    final Database db = await database;
    await db.update(
      'recipes',
      {
        'id': recipe['id'],
        'title': titleController.text,
        'ingredients': ingredientsController.text,
        'instructions': instructionsController.text,
      },
      where: 'id = ?',
      whereArgs: [recipe['id']],
    );
    Navigator.pop(context);
  }
}