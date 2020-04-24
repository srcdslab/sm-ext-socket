// example for the socket extension

#include <sourcemod>
#include <socket>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = {
	name = "socket example",
	author = "Player",
	description = "This example demonstrates downloading a http file with the socket extension",
	version = "1.1.0",
	url = "http://www.player.to/"
};
 
public void OnPluginStart() {
	// create a new tcp socket
	Socket socket = new Socket(SOCKET_TCP, OnSocketError);
	// open a file handle for writing the result
	File hFile = OpenFile("dl.htm", "wb");
	// pass the file handle to the callbacks
	socket.SetArg(hFile);
	// connect the socket
	socket.Connect(OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "www.sourcemod.net", 80);
}

public void OnSocketConnected(Socket socket, any arg) {
	// socket is connected, send the http request

	char requestStr[100];
	FormatEx(
		requestStr,
		sizeof(requestStr),
		"GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n",
		"index.php",
		"www.sourcemod.net"
	);
	socket.Send(requestStr);
}

public void OnSocketReceive(Socket socket, char[] receiveData, const int dataSize, any hFile) {
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in

	hFile.WriteString(receiveData, false);
}

public void OnSocketDisconnected(Socket socket, any hFile) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here

	CloseHandle(hFile);
	CloseHandle(socket);
}

public void OnSocketError(Socket socket, const int errorType, const int errorNum, any hFile) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(hFile);
	CloseHandle(socket);
}
