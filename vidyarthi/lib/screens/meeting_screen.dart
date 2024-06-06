import 'dart:math';
import 'package:Vidyarthi/screens/jitsi_meet_methods.dart';
import 'package:Vidyarthi/screens/resources/auth_methods.dart';
import 'package:Vidyarthi/screens/resources/home_meeting_button.dart';
import 'package:flutter/material.dart';
class MeetingScreen extends StatefulWidget {
const MeetingScreen({Key? key}) : super(key: key);

@override
State<MeetingScreen> createState() => _MeetingScreenState();
}
class _MeetingScreenState extends State<MeetingScreen> {
final AuthMethods _authMethods = AuthMethods();
final JitsiMeetMethod _jitsiMeetMethods = JitsiMeetMethod();

createNewMeeting() async {
var random = Random();
String roomName = (random.nextInt(10000000) + 10000000).toString();
_jitsiMeetMethods.createMeeting(
roomName: roomName, isAudioMuted: true, isVideoMuted: true);
}

joinMeeting(BuildContext context) {
Navigator.pushNamed(context, '/video-call');
}

@override
Widget build(BuildContext context) {
return Column(
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
HomeMeetingButton(
onPressed: () {
createNewMeeting();
},
text: 'New Meeting',
icon: Icons.videocam,
),
HomeMeetingButton(
onPressed: () => joinMeeting(context),
text: 'Join Meeting',
icon: Icons.add_box_rounded,
),
HomeMeetingButton(
onPressed: () {},
text: 'Schedule',
icon: Icons.calendar_today,
),
HomeMeetingButton(
onPressed: () {},
text: 'Share Screen',
icon: Icons.arrow_upward_rounded,
),
],
),
const Expanded(
child: Center(
child: Text(
'Create/Join Meeting with just a click',
style: TextStyle(
color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
),
))
],
);
}


}