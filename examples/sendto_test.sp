/**
 * Socket extension sendto selftest
 */

#include <sourcemod>
#include <socket>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = {
	name = "socket extension sendto selftest",
	author = "Player",
	description = "basic functionality testing",
	version = "1.0.0",
	url = "http://www.player.to/"
};
 
public void OnPluginStart() {
	view_as<Socket>(null).SetOption(DebugMode, 1);
	
	int port = 12346;

	Socket socket = new Socket(SOCKET_UDP, OnLSocketError);

	socket.Bind("0.0.0.0", port);
	socket.Listen(OnLSocketIncoming);

	Socket socket2 = new Socket(SOCKET_UDP, OnCSocketError);
	//SocketConnect(socket2, OnCSocketConnect, OnCSocketReceive, OnCSocketDisconnect, "127.0.0.1", port);
}

public void OnLSocketIncoming(Socket socket, Socket newSocket, char[] remoteIP, int remotePort, any arg) {
	PrintToServer("%s:%d connected", remoteIP, remotePort);

	newSocket.SetReceiveCallback(OnChildSocketReceive);
	newSocket.SetDisconnectCallback(OnChildSocketDisconnect);
	newSocket.SetErrorCallback(OnChildSocketError);

	newSocket.Send("\x00abc\x00def\x01\x02\x03\x04", 12);
	newSocket.SetSendqueueEmptyCallback(OnChildSocketSQEmpty);
}

public void OnLSocketError(Socket socket, const int errorType, const int errorNum, any arg) {
	LogError("listen socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public void OnChildSocketReceive(Socket socket, char[] receiveData, const int dataSize, any arg) {
	// send (echo) the received data back
	//socket.Send(receiveData);
	// close the connection/socket/handle if it matches quit
	//if (strncmp(receiveData, "quit", 4) == 0) CloseHandle(socket);
}

public void OnChildSocketSQEmpty(Socket socket, any arg) {
	PrintToServer("sq empty");
	CloseHandle(socket);
}

public void OnChildSocketDisconnect(Socket socket, any arg) {
	// remote side disconnected
	PrintToServer("disc");
	CloseHandle(socket);
}

public void OnChildSocketError(Socket socket, const int errorType, const int errorNum, any arg) {
	// a socket error occured

	LogError("child socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public void OnCSocketConnect(Socket socket, any arg) {
	// send (echo) the received data back
	//socket.Send(receiveData);
	// close the connection/socket/handle if it matches quit
	//if (strncmp(receiveData, "quit", 4) == 0) CloseHandle(socket);
}

char g_sRecvBuffer[128];
int g_irecvBufferPos = 0;

public void OnCSocketReceive(Socket socket, char[] receiveData, const int dataSize, any arg) {
	PrintToServer("received %d bytes", dataSize);

	if (g_irecvBufferPos < 512) {
		for (int i = 0; i < dataSize && g_irecvBufferPos < sizeof(g_sRecvBuffer); i++, g_irecvBufferPos++) {
			g_sRecvBuffer[g_irecvBufferPos] = receiveData[i];
		}
	}
	// send (echo) the received data back
	//socket.Send(receiveData);
	// close the connection/socket/handle if it matches quit
	//if (strncmp(receiveData, "quit", 4) == 0) CloseHandle(socket);
}

public void OnCSocketDisconnect(Socket socket, any arg) {
	char[] cmp = "\x00abc\x00def\x01\x02\x03\x04";
	int i;
	for (i = 0; i < g_irecvBufferPos && i < 12; i++) {
		if (g_sRecvBuffer[i] != cmp[i]) {
			PrintToServer("comparison failed");
			break;
		}
	}

	PrintToServer("comparison finished at pos %d/%d", i, g_irecvBufferPos);

	CloseHandle(socket);
}

public void OnCSocketError(Socket socket, const int errorType, const int errorNum, any arg) {
	// a socket error occured

	LogError("connect socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

