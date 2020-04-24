// listening socket example for the socket extension

#include <sourcemod>
#include <socket>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = {
	name = "listen socket example",
	author = "Player",
	description = "This example provides a simple echo server",
	version = "1.0.1",
	url = "http://www.player.to/"
};
 
public void OnPluginStart() {
	// enable socket debugging (only for testing purposes!)
	view_as<Socket>(null).SetOption(DebugMode, 1);


	// create a new tcp socket
	Socket socket = new Socket(SOCKET_TCP, OnSocketError);
	// bind the socket to all interfaces, port 50000
	socket.Bind("0.0.0.0", 50000);
	// let the socket listen for incoming connections
	socket.Listen(OnSocketIncoming);
}

public void OnSocketIncoming(Socket socket, Socket newSocket, char[] remoteIP, int remotePort, any arg) {
	PrintToServer("%s:%d connected", remoteIP, remotePort);

	// setup callbacks required to 'enable' newSocket
	// newSocket won't process data until these callbacks are set
	newSocket.SetReceiveCallback(OnChildSocketReceive);
	newSocket.SetDisconnectCallback(OnChildSocketDisconnected);
	newSocket.SetErrorCallback(OnChildSocketError);

	newSocket.Send("send quit to quit\n");
}

public void OnSocketError(Socket socket, const int errorType, const int errorNum, any arg) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public void OnChildSocketReceive(Socket socket, char[] receiveData, const int dataSize, any hFile) {
	// send (echo) the received data back
	socket.Send(receiveData);
	// close the connection/socket/handle if it matches quit
	if (strncmp(receiveData, "quit", 4) == 0) CloseHandle(socket);
}

public void OnChildSocketDisconnected(Socket socket, any hFile) {
	// remote side disconnected

	CloseHandle(socket);
}

public void OnChildSocketError(Socket socket, const int errorType, const int errorNum, any ary) {
	// a socket error occured

	LogError("child socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}
