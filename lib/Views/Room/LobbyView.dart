import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:universal_html/html.dart';
import 'package:zomie_app/Services/WebRTC/Models/ResponseApi.dart';
import 'package:zomie_app/Services/WebRTC/Models/RoomInfo.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class LobbyView extends StatefulWidget {
  RoomInfo roomInfo;
  Function onJoin;

  LobbyView({super.key, required this.roomInfo, required this.onJoin});
  @override
  State<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GetUserMedia();
    });
  }

  bool isLoad = false;
  GetUserMedia() async {
    if (WRTCService.instance().wrtcProducer == null) {
      WRTCService.instance().InitProducer(room_id: this.widget.roomInfo.id);
    }
    await WRTCService.instance().wrtcProducer!.GetUserMedia();
    setState(() {
      isLoad = true;
    });
  }

  double height = 0;
  double width = 0;

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Container(
      child: Center(
        child: !isLoad
            ? Text("Give permision camera & microphone")
            : WRTCService.instance().wrtcProducer!.stream == null
                ? Text("You have to give permision camera & microphone")
                : width > height
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          producerMedia(),
                          SizedBox(
                              height: width > height
                                  ? (width * 0.5) * 0.5
                                  : width * 0.9,
                              child: info())
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [producerMedia(), info()],
                      ),
      ),
    );
  }

  Widget producerMedia() {
    return SizedBox(
        width: width > height ? width * 0.5 : width * 0.9,
        height: width > height ? (width * 0.5) * 0.5 : width * 0.9,
        child: Stack(
          children: [
            WRTCService.instance().wrtcProducer!.ShowMedia(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WRTCService.instance().wrtcProducer!.ShowMicIcon(
                      onChange: () {
                    setState(() {});
                  }),
                  WRTCService.instance().wrtcProducer!.ShowCameraIcon(
                      onChange: () {
                    setState(() {});
                  }),
                ],
              ),
            )
          ],
        ));
  }

  TextEditingController tecPassword = TextEditingController();

  Widget info() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                this.widget.roomInfo.participants.toString() + " partisipants"),
          ),
          !this.widget.roomInfo.password
              ? SizedBox()
              : SizedBox(
                  width: 150.0,
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: tecPassword,
                        onChanged: (c) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                            hintText: 'Password',
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 18.0),
                            errorText: responseRoom.status_code != 200
                                ? responseRoom.message
                                : null),
                      ),
                    ),
                  ),
                ),
          JoinWidget()
        ],
      ),
    );
  }

  Widget JoinWidget() {
    if (!this.widget.roomInfo.password) {
      return JoinButton();
    } else {
      if (this.tecPassword.text.isNotEmpty) {
        return JoinButton();
      }
    }
    return SizedBox();
  }

  ResponseApi responseRoom = ResponseApi.init();
  bool joinPressing = false;
  Widget JoinButton() {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () async {
          if (!joinPressing) {
            setState(() {
              joinPressing = true;
            });
            responseRoom = await WRTCService.instance().CheckRoom(
                room_id: widget.roomInfo.id,
                room_password:
                    widget.roomInfo.password ? tecPassword.text : null);
            if (responseRoom.status_code == 200) {
              await WRTCService.instance().JoinCall(
                  room_id: widget.roomInfo.id,
                  room_password:
                      widget.roomInfo.password ? tecPassword.text : null);
              if (WRTCService.instance().inCall) {
                widget.onJoin();
              }
            }
            setState(() {
              joinPressing = false;
            });
          }
        },
        child: joinPressing
            ? CircularProgressIndicator(
                color: Colors.white,
              )
            : Text(
                "Join now",
                style: TextStyle(color: Colors.white),
              ),
        style: ElevatedButton.styleFrom(
          // shape: CircleBorder(),
          padding: EdgeInsets.all(17),
          backgroundColor: Colors.teal, // <-- Button color
          // foregroundColor: Colors.red, // <-- Splash color
        ),
      ),
    );
  }
}