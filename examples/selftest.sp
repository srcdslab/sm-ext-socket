/**
 * Socket extension selftest
 */

#include <sourcemod>
#include <socket>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = {
	name = "socket extension selftest",
	author = "Player",
	description = "basic functionality testing",
	version = "1.1.0",
	url = "http://www.player.to/"
};

int g_iGoalsReached;
int g_iTrapsReached;

int g_iTest;
public void OnGameFrame() {
	if (g_iTest == 0) {
		g_iTest++;

		view_as<Socket>(null).SetOption(DebugMode, 1);

		selfTest1();
	}
}

/**
 * TEST #1 - binary data over tcp
 *
 * stuff tested:
 * - create, close
 * - connect
 * - send, receive
 * - listen
 * - sendQueueEmpty
 * - setoption reuseaddr
 * - data containing x00
 *
 * This test is using three sockets:
 * - Listening socket on port 12345
 * - A socket which tries to connect to the listening socket and receives data
 * - the child socket which sends the data
 */
void selfTest1() {
	g_iGoalsReached = 0;
	g_iTrapsReached = 0;
	CreateTimer(3.0, selfTest1Terminate);
	PrintToServer("* |socket selftest| test #1 running");

	Socket socket = new Socket(SOCKET_TCP, OnSocketErrorTrap);

	socket.SetOption(SocketReuseAddr, 1);

	socket.Bind("0.0.0.0", 12345);
	socket.Listen(Test1_OnListenSocketIncoming);

	Socket socket2 = new Socket(SOCKET_TCP, OnSocketErrorTrap);
	socket2.Connect(OnSocketConnectGoal, Test1_OnReceiveSocketReceive, Test1_OnReceiveSocketDisconnect, "127.0.0.1", 12345);
}

public Action selfTest1Terminate(Handle timer) {
	if (g_iGoalsReached == 6 && g_iTrapsReached == 0) {
		PrintToServer("* |socket selftest| ** test #1 passed **");
		selfTest2();
	} else {
		PrintToServer("* |socket selftest| ** test #1 failed **");
	}

	return Plugin_Stop;
}

/**
 * TEST #2 - reuse listening address from test #1
 *
 * stuff tested:
 * - create, close
 * - listen
 * - setoption reuseaddr
 *
 * This test is using one socket:
 * - Listening socket on port 12345
 */
void selfTest2() {
	g_iGoalsReached = 0;
	g_iTrapsReached = 0;
	CreateTimer(4.0, selfTest2Terminate);
	PrintToServer("* |socket selftest| test #2 running");

	Socket socket = new Socket(SOCKET_TCP, OnSocketErrorTrap);

	socket.SetOption(SocketReuseAddr, 1);

	socket.Bind("0.0.0.0", 12345);
	socket.Listen(OnSocketIncomingTrap);

	CloseHandle(socket);

	g_iGoalsReached++;
}

public Action selfTest2Terminate(Handle timer) {
	if (g_iGoalsReached == 1 && g_iTrapsReached == 0) {
		PrintToServer("* |socket selftest| ** test #2 passed **");
		selfTest3();
	} else {
		PrintToServer("* |socket selftest| ** test #2 failed **");
	}

	return Plugin_Stop;
}

void selfTest3() {
	g_iGoalsReached = 0;
	g_iTrapsReached = 0;
	CreateTimer(1.0, selfTest3Terminate);
	PrintToServer("* |socket selftest| test #3 running");

	Socket socket[20];
	
	for (int count = 1; count <= 20; count++) {
		for (int i = 0; i < count; i++) {
			socket[i] = new Socket(SOCKET_TCP, OnSocketErrorTrap);
		}

		for (int i = 0; i < count; i++) {
			CloseHandle(socket[i]);
		}
	}

	g_iGoalsReached++;
}

public Action selfTest3Terminate(Handle timer) {
	if (g_iGoalsReached == 1 && g_iTrapsReached == 0) {
		PrintToServer("* |socket selftest| ** test #3 passed **");
		selfTest4();
	} else {
		PrintToServer("* |socket selftest| ** test #3 failed **");
	}

	return Plugin_Stop;
}

/**
 * TEST #4 - connect, closehandle
 *
 * stuff tested:
 * - create, close
 * - connect
 * - listen
 */
void selfTest4() {
	g_iGoalsReached = 0;
	g_iTrapsReached = 0;
	CreateTimer(5.0, selfTest4Terminate);
	PrintToServer("* |socket selftest| test #4 running");

	Socket listenSocket = new Socket(SOCKET_TCP, OnSocketErrorTrap);

	listenSocket.SetOption(SocketReuseAddr, 1);

	listenSocket.Bind("0.0.0.0", 12345);
	listenSocket.Listen(Test3_OnListenSocketIncoming);

	Socket socket[8];
	
	for (int count = 1; count <= 8; count++) {
		for (int i = 0; i < count; i++) {
			socket[i] = new Socket(SOCKET_TCP, OnSocketErrorTrap);
		}

		for (int i = 0; i < count; i++) {
			socket[i].Connect(OnSocketConnectGoal, OnSocketReceiveTrap, OnSocketDisconnectGoal, "127.0.0.1", 12345);
		}
	}

	CloseHandle(listenSocket);

	g_iGoalsReached++;
}

public Action selfTest4Terminate(Handle timer) {
	if (g_iGoalsReached == 109 && g_iTrapsReached == 0) {
		PrintToServer("* |socket selftest| ** test #4 passed **");
		selfTest5();
	} else {
		PrintToServer("* |socket selftest| ** test #4 failed ** (%d goals of 109)", g_iGoalsReached);
	}

	return Plugin_Stop;
}

void selfTest5() {
}

// ------------------------------------- TEST 1 callbacks -------------------------------------

public void Test1_OnListenSocketIncoming(Socket socket, Socket newSocket, char[] remoteIP, int remotePort, any arg) {
	newSocket.SetReceiveCallback(OnSocketReceiveTrap);
	newSocket.SetDisconnectCallback(OnSocketDisconnectTrap);
	newSocket.SetErrorCallback(OnSocketErrorTrap);

	newSocket.Send("\x00abc\x00def\x01\x02\x03\x04", 12);
	newSocket.SetSendqueueEmptyCallback(Test1_OnChildSocketSQEmpty);

	PrintToServer("* |socket selftest| goal Test1_OnListenSocketIncoming reached");
	g_iGoalsReached++;

	// close listening socket
	CloseHandle(socket);

	PrintToServer("* |socket selftest| goal Test1_OnListenSocketIncoming - CloseHandle reached");
	g_iGoalsReached++;
}

public void Test1_OnChildSocketSQEmpty(Socket socket, any arg) {
	CloseHandle(socket);
	PrintToServer("* |socket selftest| goal Test1_OnChildSocketSQEmpty reached");
	g_iGoalsReached++;
}

char g_sRecvBuffer[128];
int g_iRecvBufferPos = 0;

public void Test1_OnReceiveSocketReceive(Socket socket, char[] receiveData, const int dataSize, any arg) {
	PrintToServer("received %d bytes", dataSize);

	if (g_iRecvBufferPos < 512) {
		for (int i = 0; i < dataSize && g_iRecvBufferPos < sizeof(g_sRecvBuffer); i++, g_iRecvBufferPos++) {
			g_sRecvBuffer[g_iRecvBufferPos] = receiveData[i];
		}
	}
}

public void Test1_OnReceiveSocketDisconnect(Socket socket, any arg) {
	PrintToServer("* |socket selftest| goal Test1_OnReceiveSocketDisconnect reached");
	g_iGoalsReached++;

	char cmp[] = "\x00abc\x00def\x01\x02\x03\x04";
	int i;
	for (i = 0; i < g_iRecvBufferPos && i < 12; i++) {
		if (g_sRecvBuffer[i] != cmp[i]) {
			PrintToServer("comparison failed");
			break;
		}
	}

	CloseHandle(socket);

	if (i == 12) {
		PrintToServer("* |socket selftest| goal Test1_OnReceiveSocketDisconnect - i=12 reached");
		g_iGoalsReached++;
	} else {
		PrintToServer("* |socket selftest| trap Test1_OnReceiveSocketDisconnect - i=%d!=12 triggered", i);
		g_iTrapsReached++;
	}
}

// ------------------------------------- TEST 3 callbacks -------------------------------------

public void Test3_OnListenSocketIncoming(Socket socket, Socket newSocket, char[] remoteIP, int remotePort, any arg) {
	CloseHandle(newSocket);
	g_iGoalsReached++;
}

// ------------------------------------- common callbacks -------------------------------------

public void OnSocketConnectGoal(Socket socket, any arg) {
	g_iGoalsReached++;
}
public void OnSocketReceiveGoal(Socket socket, char[] receiveData, const int dataSize, any arg) {
	g_iGoalsReached++;
}
public void OnSocketDisconnectGoal(Socket socket, any arg) {
	g_iGoalsReached++;
}
public void OnSocketErrorGoal(Socket socket, const int errorType, const int errorNum, any arg) {
	g_iGoalsReached++;
}
public void OnSocketIncomingGoal(Socket socket, Socket newSocket, char[] remoteIP, int remotePort, any arg) {
	g_iGoalsReached++;
}

public void OnSocketConnectTrap(Socket socket, any arg) {
	PrintToServer("* |socket selftest| trap OnSocketConnectTrap triggered");
	g_iTrapsReached++;
}
public void OnSocketReceiveTrap(Socket socket, char[] receiveData, const int dataSize, any arg) {
	PrintToServer("* |socket selftest| trap OnSocketReceiveTrap triggered (%d bytes received)", dataSize);
	g_iTrapsReached++;
}
public void OnSocketDisconnectTrap(Socket socket, any arg) {
	PrintToServer("* |socket selftest| trap OnSocketDisconnectTrap triggered");
	g_iTrapsReached++;
}
public void OnSocketErrorTrap(Socket socket, const int errorType, const int errorNum, any arg) {
	PrintToServer("* |socket selftest| trap OnSocketErrorTrap triggered (error %d, errno %d)", errorType, errorNum);
	g_iTrapsReached++;
}
public void OnSocketIncomingTrap(Socket socket, Socket newSocket, char[] remoteIP, int remotePort, any arg) {
	PrintToServer("* |socket selftest| trap OnSocketIncomingTrap triggered");
	g_iTrapsReached++;
}

// EOF

