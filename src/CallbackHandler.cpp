#include "CallbackHandler.h"

#include <unordered_set>
#include <vector>

#include "Callback.h"
#include "SocketHandler.h"

// No logging in this file: AddCallback runs on the io_service thread, and the std::cout
// writes that used to be here segfaulted the x64 build (#12).

void CallbackHandler::AddCallback(Callback* callback) {
	if (!callback->IsValid()) {
		delete callback;
		return;
	}

	boost::mutex::scoped_lock l(callbackQueueMutex);

	callbackQueue.push_back(callback);
}

void CallbackHandler::RemoveCallbacks(SocketWrapper* sw) {
	std::vector<SocketWrapper*> orphans;

	{ // lock
		boost::mutex::scoped_lock l(callbackQueueMutex);

		for (std::deque<Callback*>::iterator it=callbackQueue.begin(); it!=callbackQueue.end(); ) {
			Callback* cb = *it;
			bool incoming = (cb->callbackEvent == CallbackEvent_Incoming);

			if (cb->socketWrapper == sw) {
				// An Incoming callback that never ran carries a connection nobody holds a
				// handle to: once its listener is gone it would stay open in socketList
				// until the extension unloads, so close it below.
				if (incoming && cb->additionalData[0]) {
					orphans.push_back((SocketWrapper*) cb->additionalData[0]);
				}

				delete cb;
				it = callbackQueue.erase(it);
			} else if (incoming && cb->additionalData[0] == sw) {
				// The accepted socket itself is being destroyed: drop the listener's
				// Incoming callback that still points to it.
				delete cb;
				it = callbackQueue.erase(it);
			} else {
				it++;
			}
		}
	} // ~lock

	for (std::vector<SocketWrapper*>::iterator it=orphans.begin(); it!=orphans.end(); it++) {
		socketHandler.DestroySocket(*it);
	}
}

void CallbackHandler::ExecuteQueuedCallbacks() {
	Callback* cb = FetchFirstCallback();
	if (!cb) return;

//	cb->isExecuting = true;
	cb->Execute();
	delete cb;
}

Callback* CallbackHandler::FetchFirstCallback() {
	boost::mutex::scoped_lock l(callbackQueueMutex);

	// Return the first callback that can run. One that cannot run yet (no plugin callback
	// set for that event, or the Receive of an accepted socket whose Incoming callback has
	// not run) used to stall the whole queue (#12). Now it only holds back the later
	// callbacks of its own socket, so each socket still gets its events in order.
	std::unordered_set<SocketWrapper*> blocked;

	for (std::deque<Callback*>::iterator it=callbackQueue.begin(); it!=callbackQueue.end(); it++) {
		Callback* cb = *it;

		if (!blocked.empty() && blocked.count(cb->socketWrapper)) continue;

		if (!cb->IsExecutable()) {
			blocked.insert(cb->socketWrapper);
			continue;
		}

		callbackQueue.erase(it);
		return cb;
	}

	return NULL;
}

CallbackHandler callbackHandler;
