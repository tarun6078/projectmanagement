import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:Vidyarthi/screens/login_screen.dart';
import 'package:flutter_screenshot_switcher/flutter_screenshot_switcher.dart';


class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  const ChatScreen({Key? key, required String title}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? messageText;
  User? loggedInUser;
  var messageTextController = TextEditingController();
  var searchTextController = TextEditingController();
  String searchQuery = '';
  List<DocumentSnapshot> searchResults = [];
  DocumentSnapshot? selectedUser;
  List<DocumentSnapshot> recentChats = []; // Added to store recent chats
  bool isScreenshotDisabled = false; // Added to keep track of screenshot status
  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
        loadRecentChats();
        loadScreenshotStatus(); // Load screenshot status for the current user
      }
    } catch (e) {
      print(e);
    }
  }

  void loadRecentChats() async {
    final QuerySnapshot snapshot = await _firestore
        .collection('recent_chats')
        .doc(loggedInUser!.uid)
        .collection('chats')
        .orderBy('last_message_time', descending: true)
        .limit(5)
        .get();

    setState(() {
      recentChats = snapshot.docs;
    });
  }

  void loadScreenshotStatus() async {
    // Check if user is admin (replace with your admin check logic)
    final isAdmin =  loggedInUser!.uid == 'admin';;

    // Load data based on user type
    final snapshot = await (isAdmin
        ? _firestore.collection('admins').doc(loggedInUser!.uid).get()
        : _firestore.collection('users').doc(loggedInUser!.uid).get());

    setState(() {
      isScreenshotDisabled = snapshot['disable_screenshot'] ?? false;
    });
  }

  void toggleScreenshotStatus(bool value) {
    // Update screenshot status for the current user in Firestore
    final collectionReference = loggedInUser!.uid == 'admins'
        ? _firestore.collection('admins')
        : _firestore.collection('users');
    collectionReference.doc(loggedInUser!.uid).update({
      'disable_screenshot': value,
    });

    setState(() {
      isScreenshotDisabled = value;
    });

    // Update screenshot switcher accordingly
    if (value) {
      FlutterScreenshotSwitcher.disableScreenshots();
    } else {
      FlutterScreenshotSwitcher.enableScreenshots();
    }
  }

  void searchUsers(String query) async {
    // Combine results from users and admins (if applicable)
    List<DocumentSnapshot> allResults = [];

    // Search users collection (name and email)
    final userResults = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
    allResults.addAll(userResults.docs);

    final userEmailResults = await _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
    allResults.addAll(userEmailResults.docs);

    // Check if admin search is enabled (replace with your check)
    final isAdminSearchEnabled = true; // Replace with your admin search logic

    if (isAdminSearchEnabled) {
      // Search admins collection (name and email)
      final adminResults = await _firestore
          .collection('admins')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      allResults.addAll(adminResults.docs);

      final adminEmailResults = await _firestore
          .collection('admins')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      allResults.addAll(adminEmailResults.docs);
    }

    // Update state with combined results
    setState(() {
      searchResults = allResults;
    });
  }


  String getChatId(String user1Id, String user2Id) {
    return user1Id.hashCode <= user2Id.hashCode
        ? '${user1Id}_$user2Id'
        : '${user2Id}_${user1Id}';
  }

  @override
  Widget build(BuildContext context)  {
    return WillPopScope(
        onWillPop: () async {
          if (selectedUser != null) {
            setState(() {
              selectedUser = null; // Clear selectedUser when pressing back
            });
            return false; // Do not pop the route
          }
          return true; // Let the system handle the back button
        },
   child: Scaffold(
      appBar: AppBar(
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), // Change icon to settings icon
            onPressed: () {
              showUserProfileDialog(); // Show user profile dialog
            },
          ),
        ],
        title: const Text(
          'Samvaad App',
          style: TextStyle(
            color: Colors.white, // Set the color to white
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectedUser == null) getSearchBar(),
            if (selectedUser == null) getRecentChats(), // Display recent chats
            if (selectedUser == null)
              Expanded(child: getSearchResultsList())
            else
              Expanded(
                child: PrivateChatScreen(
                  chatId: getChatId(loggedInUser!.uid, selectedUser!.id),
                  receiverEmail: selectedUser!['email'] ?? 'Unknown Email',
                  receiverName: selectedUser!['name'] ?? 'Unknown Name',
                  firestore: _firestore,
                  loggedInUser: loggedInUser,
                ),
              ),
            if (selectedUser != null) getUserMessageBox(),
          ],
        ),
      ),
   ),
    );
  }

  // Add the showUserProfileDialog method
  void showUserProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text("User Profile"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (loggedInUser != null)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(loggedInUser!.photoURL ?? ''),
                      ),
                      title: Text(loggedInUser!.displayName ?? ''),
                      subtitle: Text(loggedInUser!.email ?? ''),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _auth.signOut();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: Text("Logout"),
                      ),
                      Switch(
                        value: isScreenshotDisabled,
                        onChanged: (value) {
                          setState(() {
                            isScreenshotDisabled = value;
                          });
                          if (isScreenshotDisabled) {
                            FlutterScreenshotSwitcher.disableScreenshots();
                          } else {
                            FlutterScreenshotSwitcher.enableScreenshots();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget getSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchTextController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
          if (value.isNotEmpty) {
            searchUsers(value);
          } else {
            setState(() {
              searchResults = [];
            });
          }
        },
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          hintText: 'Search for users...',
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
  Widget getRecentChats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Recent Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(
          height: 150, // Set the height based on your UI requirements
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: recentChats.length,
            itemBuilder: (context, index) {
              var user = recentChats[index].data() as Map<String, dynamic>;
              return Dismissible(
                key: UniqueKey(),
                background: Container(
                  color: Colors.purple,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 20.0),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                onDismissed: (direction) {
                  setState(() {
                    // Delete the chat from recent chats
                    _deleteRecentChat(recentChats[index]);
                    recentChats.removeAt(index);
                  });
                },
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedUser = recentChats[index];
                      searchTextController.clear();
                      searchQuery = '';
                      searchResults = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: user['photoUrl'] != null
                                  ? NetworkImage(user['photoUrl'])
                                  : null,
                              child: user['photoUrl'] == null
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user['name'] ?? 'Unknown Name',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _deleteRecentChat(DocumentSnapshot user) {
    _firestore
        .collection('recent_chats')
        .doc(loggedInUser!.uid)
        .collection('chats')
        .doc(user.id)
        .delete();
  }


  Widget getSearchResultsList() {
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        var user = searchResults[index].data() as Map<String, dynamic>;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
            child: user['photoUrl'] == null ? Icon(Icons.person) : null,
          ),
          title: Text(user['name'] ?? 'Unknown Name'),
          subtitle: Text(user['email'] ?? 'Unknown Email'),
          onTap: () {
            setState(() {
              selectedUser = searchResults[index];
              searchTextController.clear();
              searchQuery = '';
              searchResults = [];
              // Add the selected user to recent chats
              addToRecentChats(selectedUser!);
            });
          },
        );
      },
    );
  }

  void addToRecentChats(DocumentSnapshot user) {
    // Add the user to recent chats collection
    _firestore
        .collection('recent_chats')
        .doc(loggedInUser!.uid)
        .collection('chats')
        .doc(user.id)
        .set({
      'name': user['name'],
      'email': user['email'],
      'last_message_time': FieldValue.serverTimestamp(),
    });
    // Refresh recent chats
    loadRecentChats();
  }

  Container getUserMessageBox() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.deepPurpleAccent, width: 2.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: messageTextController,
              onChanged: (value) {
                setState(() {
                  messageText = value;
                });
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                hintText: 'Type your message here...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (messageText != null && messageText!.trim().isNotEmpty) {
                _firestore
                    .collection('chats')
                    .doc(getChatId(loggedInUser!.uid, selectedUser!.id))
                    .collection('messages')
                    .add({
                  'text': messageText,
                  'sender': loggedInUser!.email,
                  'receiver': selectedUser!['email'],
                  'timestamp': FieldValue.serverTimestamp(),
                  'seen': true, // Initially set seen to false
                });
                messageTextController.clear();
                setState(() {
                  messageText = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class PrivateChatScreen extends StatelessWidget {
  final String chatId;
  final String receiverEmail;
  final String receiverName;
  final FirebaseFirestore firestore;
  final User? loggedInUser;

  const PrivateChatScreen({
    required this.chatId,
    required this.receiverEmail,
    required this.receiverName,
    required this.firestore,
    required this.loggedInUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(



          title: Text(receiverName),
          subtitle: Text(receiverEmail),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data!.docs;
              List<MessageBubble> messageBubbles = [];
              for (var message in messages) {
                final messageId = message.id;
                final messageText = message['text'] ?? '';
                final messageSender = message['sender'] ?? '';
                final timestamp = message['timestamp'] ?? Timestamp.now(); // Get timestamp
                final seen = message['seen'] ?? true; // Get seen status

                final messageBubble = MessageBubble(
                  messageId: messageId,
                  sender: messageSender,
                  text: messageText,
                  isMe: loggedInUser!.email == messageSender,
                  onDelete: (messageId) {
                    // Delete message
                    firestore
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .doc(messageId)
                        .delete();
                  },
                  timestamp: timestamp, // Pass timestamp to MessageBubble
                  seen: seen, // Pass seen status to MessageBubble
                );

                messageBubbles.add(messageBubble);
              }
              return ListView(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                children: messageBubbles,
              );
            },
          ),
        ),
      ],
    );
  }
}

class MessageBubble extends StatefulWidget {
  final String messageId;
  final String sender;
  final String text;
  final bool isMe;
  final bool seen; // Add seen property
  final Function(String) onDelete;
  final Timestamp timestamp; // Add timestamp

  const MessageBubble({
    required this.messageId,
    required this.sender,
    required this.text,
    required this.isMe,
    required this.onDelete,
    required this.timestamp, // Include timestamp
    required this.seen, // Include seen property
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool isEditing = false;
  TextEditingController editingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showOptionsDialog();
      },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Display sender and timestamp
            Row(
              mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  widget.sender,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(widget.timestamp.toDate()), // Format timestamp
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.black54,
                  ),
                ),
                // Display seen status
                SizedBox(width: 8),
                Icon(
                  widget.seen ? Icons.done_all : Icons.done_all_outlined,
                  color: widget.seen ? Colors.blue : Colors.grey,
                  size: 16,
                ),
              ],
            ),
            Material(
              borderRadius: BorderRadius.circular(15.0),
              elevation: 5.0,
              color: widget.isMe ? Colors.deepPurpleAccent : Colors.white,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7, // Limit width to 70% of screen width
                ),
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: isEditing
                    ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: editingController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        // Save edited message
                        // For simplicity, we're directly updating the message in Firestore
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(widget.messageId)
                            .update({'text': editingController.text});
                        setState(() {
                          isEditing = false;
                        });
                      },
                    ),
                  ],
                )
                    : Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.isMe ? Colors.white : Colors.black,
                    fontSize: _calculateFontSize(), // Dynamically calculate font size based on message length
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to calculate font size based on message length
  double _calculateFontSize() {
    if (widget.text.length <= 20) {
      return 18.0;
    } else if (widget.text.length <= 50) {
      return 16.0;
    } else {
      return 14.0;
    }
  }

  void showOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select an option"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete"),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete(widget.messageId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
