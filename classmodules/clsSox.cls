VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsSox"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
'ignitionServer is (C)  Keith Gable, Nigel Jones and Reid Burke.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'                     Nigel Jones (DigiGuy) <digiguy@ignition-project.com>
'                     Reid Burke  (AirWalk) <airwalk@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: clsSox.cls,v 1.4 2004/05/28 21:27:35 ziggythehamster Exp $
'
'
'This program is free software.
'You can redistribute it and/or modify it under the terms of the
'GNU General Public License as published by the Free Software Foundation; either version 2 of the License,
'or (at your option) any later version.
'
'This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
'Without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
'See the GNU General Public License for more details.
'
'You should have received a copy of the GNU General Public License along with this program.
'if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Option Explicit

#Const Debugging = 0

Public Enum enmSoxState
    ' Used
    soxDisconnected = 0&
    soxListening = 1&
    soxConnecting = 2&
    soxConnected = 3&
    soxDataRecv = 4&
    soxDataSend = 5&
    soxClosing = 6&
    soxBound = 10& ' The socket has been bound to its current Port and Address
    soxERROR = -1& ' This is here so the outside calling functions can test function return values eg. If Sox.CloseIt(123) = soxERROR Then ... but is not used within the Class module
End Enum

Public Enum enmSoxOptions
    ' Set & Get Compatible Options
    soxSO_BROADCAST = &H20& 'BOOL Allow transmission of broadcast messages on the socket.
    soxSO_DEBUG = &H1& 'BOOL Record debugging information.
'    soxSO_SO_DONTLINGER = Not soxSO_LINGER 'BOOL Do not block close waiting for unsent data to be sent. Setting this option is equivalent to setting SO_LINGER with l_onoff set to zero.
    soxSO_DONTROUTE = &H10& 'BOOL Do not route: send directly to interface.
    soxSO_KEEPALIVE = &H8& 'BOOL Send keepalives
    soxSO_LINGER = &H80& 'struct LINGER  Linger on close if unsent data is present.
    soxSO_OOBINLINE = &H100& 'BOOL Receive out-of-band data in the normal data stream. (See section DECnet Out-Of-band data for a discussion of this topic.)
    soxSO_RCVBUF = &H1002& 'int Specify the total per-socket buffer space reserved for receives. This is unrelated to SO_MAX_MSG_SIZE or the size of a TCP window.
    soxSO_REUSEADDR = &H4& 'BOOL Allow the socket to be bound to an address that is already in use. (See bind.)
    soxSO_SNDBUF = &H1001& 'int Specify the total per-socket buffer space reserved for sends. This is unrelated to SO_MAX_MSG_SIZE or the size of a TCP window.
    ' Inverting TCP_NODELAY value to create unique value of -2
    soxSO_TCP_NODELAY = Not &H1& 'BOOL Disables the Nagle algorithm for send coalescing.
    ' Get ONLY Compatible Options
    soxSO_USELOOPBACK = &H40& 'bypass hardware when possible
    soxSO_ACCEPTCONN = &H2& 'BOOL Socket is listening.
    soxSO_ERROR = &H1007& 'int Retrieve error status and clear.
    soxSO_TYPE = &H1008& 'Get Socket Type (From FTP - Experimental) (Seems to always returns 1 for a valid TCP socket, -1 for a closed socket)
End Enum

'API Defined
Private Type typSocketAddr
    sin_family As Integer
    sin_port As Integer
    sin_addr As Long
    sin_zero(7) As Byte
End Type
Private Const SOCKADDR_SIZE = 16

'Class module Defined
Private Type typSocket
    Socket As Long ' The actual WinSock API socket number
    SocketAddr As typSocketAddr ' Info about the connection
    State As enmSoxState ' Not FULLY implemented
    uMsg As Long ' Server (-1) / Client (0) Socket (Server = A Socket that has a connection to the Server / Client = A Socket that was created in Accept that connected to us)
End Type

Private Const WSADescription_Len As Long = 256 '(Confirmed)
Private Const WSASYS_Status_Len As Long = 128 '(Confirmed)

'API Defined
'Contains information about our current WinSock implementation
Private Type typWSAData
    wversion As Integer
    wHighVersion As Integer
    szDescription(0 To WSADescription_Len) As Byte
    szSystemStatus(0 To WSASYS_Status_Len) As Byte
    iMaxSockets As Integer
    iMaxUdpDg As Integer
    lpVendorInfo As Long
End Type

Private Type typLinger
    l_onoff As Integer
    l_linger As Integer
End Type

'VB WinSock OCX Defined Error codes
Public Enum enmError
    sckOutOfMemory = 7                'Out of memory
    sckInvalidPropertyValue = 380     'The property value is invalid
    sckGetNotSupported = 394          'The property cannot be read
    sckSetNotSupported = 383          'The property is read-only
    sckBadState = 40006               'Wrong protocol or connection state for the requested transaction or request
    sckInvalidArg = 40014             'The argument passed to a function was not in the correct format or in the specified range
    sckSuccess = 40017                'Successful
    sckUnsupported = 40018            'Unsupported variant type
    sckInvalidOp = 40020              'Invalid operation at current state
    sckOutOfRange = 40021             'Argument is out of range
    sckWrongProtocol = 40026          'Wrong protocol for the requested transaction or request
    sckOpCanceled = 1004              'The operation was canceled
    sckInvalidArgument = 10014        'The requested address is a broadcast address, but flag is not set
    sckWouldBlock = 10035             'Socket is non-blocking and the specified operation will block
    sckInProgress = 10036             'A blocking Winsock operation in progress
    sckAlreadyComplete = 10037        'The operation is completed. No blocking operation in progress
    sckNotSocket = 10038              'The descriptor is not a socket
    sckMsgTooBig = 10040              'The datagram is too large to fit into the buffer and is truncated
    sckPortNotSupported = 10043       'The specified port is not supported
    sckAddressInUse = 10048           'Address in use
    sckAddressNotAvailable = 10049    'Address not available from the local machine
    sckNetworkSubsystemFailed = 10050 'Network subsystem failed
    sckNetworkUnreachable = 10051     'The network cannot be reached from this host at this time
    sckNetReset = 10052               'Connection has timed out when SO_KEEPALIVE is set
    sckConnectAborted = 10053         'Connection is aborted due to timeout or other failure
    sckConnectionReset = 10054        'The connection is reset by remote side
    sckNoBufferSpace = 10055          'No buffer space is available
    sckAlreadyConnected = 10056       'Socket is already connected
    sckNotConnected = 10057           'Socket is not connected
    sckSocketShutdown = 10058         'Socket has been shut down
    sckTimedout = 10060               'Socket has been shut down
    sckConnectionRefused = 10061      'Connection is forcefully rejected
    sckNotInitialized = 10093         'WinsockInit should be called first
    sckHostNotFound = 11001           'Authoritative answer: Host not found
    sckHostNotFoundTryAgain = 11002   'Non-Authoritative answer: Host not found
    sckNonRecoverableError = 11003    'Non-recoverable errors
    sckNoData = 11004                 'Valid name, no data record of requested type
End Enum

'All WinSock error constants are based on WSABASEERR
Private Const WSABASEERR As Long = 10000
'WinSock definitions of regular Microsoft C error constants
Private Const WSAEINTR As Long = (WSABASEERR + 4) 'Interrupted function call
Private Const WSAEBADF As Long = (WSABASEERR + 9)
Private Const WSAEACCES As Long = (WSABASEERR + 13) 'Permission Denied
Private Const WSAEFAULT As Long = (WSABASEERR + 14) 'Bad address
Private Const WSAEINVAL As Long = (WSABASEERR + 22) 'Invalid argument
Private Const WSAEMFILE As Long = (WSABASEERR + 24) 'Too many open files
'Windows Sockets definitions of regular Berkeley error constants
Private Const WSAEWOULDBLOCK As Long = (WSABASEERR + 35) 'Resource temporarily unavailable
Private Const WSAEINPROGRESS As Long = (WSABASEERR + 36) 'Operation now in progress
Private Const WSAEALREADY As Long = (WSABASEERR + 37) 'Operation already in progress
Private Const WSAENOTSOCK As Long = (WSABASEERR + 38) 'Socket operation on non-socket
Private Const WSAEDESTADDRREQ As Long = (WSABASEERR + 39) 'Destination address required
Private Const WSAEMSGSIZE As Long = (WSABASEERR + 40) 'Message too long
Private Const WSAEPROTOTYPE As Long = (WSABASEERR + 41) 'Protocol wrong type for socket
Private Const WSAENOPROTOOPT As Long = (WSABASEERR + 42) 'Bad protocol option
Private Const WSAEPROTONOSUPPORT As Long = (WSABASEERR + 43) 'Protocol not supported
Private Const WSAESOCKTNOSUPPORT As Long = (WSABASEERR + 44) 'Socket type not supported
Private Const WSAEOPNOTSUPP As Long = (WSABASEERR + 45) 'Operation not supported
Private Const WSAEPFNOSUPPORT As Long = (WSABASEERR + 46) 'Protocol family not supported
Private Const WSAEAFNOSUPPORT As Long = (WSABASEERR + 47) 'Address family not supported by protocol family
Private Const WSAEADDRINUSE As Long = (WSABASEERR + 48) 'Address already in use
Private Const WSAEADDRNOTAVAIL As Long = (WSABASEERR + 49) 'Cannot assign requested address
Private Const WSAENETDOWN As Long = (WSABASEERR + 50) 'Network is down
Private Const WSAENETUNREACH As Long = (WSABASEERR + 51) 'Network is unreachable
Private Const WSAENETRESET As Long = (WSABASEERR + 52) 'Network dropped connection on reset
Private Const WSAECONNABORTED As Long = (WSABASEERR + 53) 'Software caused connection abort
Private Const WSAECONNRESET As Long = (WSABASEERR + 54) 'Connection reset by peer
Private Const WSAENOBUFS As Long = (WSABASEERR + 55) 'No buffer space available
Private Const WSAEISCONN As Long = (WSABASEERR + 56) 'Socket is already connected
Private Const WSAENOTCONN As Long = (WSABASEERR + 57) 'Socket is not connected
Private Const WSAESHUTDOWN As Long = (WSABASEERR + 58) 'Cannot send after socket shutdown
Private Const WSAETOOMANYREFS As Long = (WSABASEERR + 59) 'Too many references: can't splice (UnConfirmed Description)
Private Const WSAETIMEDOUT As Long = (WSABASEERR + 60) 'Connection timed out
Private Const WSAECONNREFUSED As Long = (WSABASEERR + 61) 'Connection refused
Private Const WSAELOOP As Long = (WSABASEERR + 62) 'Too many levels of symbolic links (UnConfirmed Description)
Private Const WSAENAMETOOLONG As Long = (WSABASEERR + 63) 'File name too long (UnConfirmed Description)
Private Const WSAEHOSTDOWN As Long = (WSABASEERR + 64) 'Host is down
Private Const WSAEHOSTUNREACH As Long = (WSABASEERR + 65) 'No route to host
Private Const WSAENOTEMPTY As Long = (WSABASEERR + 66) 'Directory not empty (UnConfirmed Description)
Private Const WSAEPROCLIM As Long = (WSABASEERR + 67) 'Too many processes
Private Const WSAEUSERS As Long = (WSABASEERR + 68) 'Too many users (UnConfirmed Description)
Private Const WSAEDQUOT As Long = (WSABASEERR + 69) 'Disk quota exceeded (UnConfirmed Description)
Private Const WSAESTALE As Long = (WSABASEERR + 70) 'Stale NFS file handle (UnConfirmed Description)
Private Const WSAEREMOTE As Long = (WSABASEERR + 71) 'Too many levels of remote in path (UnConfirmed Description)
'Extended Windows Sockets error constant definitions
Private Const WSASYSNOTREADY As Long = (WSABASEERR + 91) 'Network subsystem is unavailable
Private Const WSAVERNOTSUPPORTED As Long = (WSABASEERR + 92) 'WINSOCK.DLL version out of range
Private Const WSANOTINITIALISED As Long = (WSABASEERR + 93) 'Successful WSAStartup not yet performed
Private Const WSAEDISCON1 As Long = (WSABASEERR + 94) 'Graceful shutdown in progress
'Private Const WSA_INVALID_HANDLE    '(OS Dependent) Specified event object handle is invalid
'Private Const WSA_INVALID_PARAMETER '(OS Dependent) One or more parameters are invalid
'Private Const WSAINVALIDPROCTABLE   '(OS Dependent) Invalid procedure table from service provider
'Private Const WSAINVALIDPROVIDER    '(OS Dependent) Invalid service provider version number
'Private Const WSA_IO_INCOMPLETE     '(OS Dependent) Overlapped I/O event object not in signaled state
'Private Const WSA_IO_PENDING        '(OS Dependent) Overlapped operations will complete later
'Private Const WSA_NOT_ENOUGH_MEMORY '(OS Dependent) Insufficient memory available
'Private Const WSAPROVIDERFAILEDINIT '(OS Dependent) Unable to initialize a service provider
'Private Const WSA_OPERATION_ABORTED '(OS Dependent) Overlapped operation aborted
Private Const WSAEDISCON2 As Long = (WSABASEERR + 101) 'Graceful shutdown in progress
Private Const WSAENOMORE As Long = (WSABASEERR + 102)
Private Const WSAECANCELLED As Long = (WSABASEERR + 103)
Private Const WSAEINVALIDPROCTABLE As Long = (WSABASEERR + 104)
Private Const WSAEINVALIDPROVIDER As Long = (WSABASEERR + 105)
Private Const WSAEPROVIDERFAILEDINIT As Long = (WSABASEERR + 106)
Private Const WSASYSCALLFAILURE As Long = (WSABASEERR + 107) '(OS Dependent) System call failure
Private Const WSASERVICE_NOT_FOUND As Long = (WSABASEERR + 108)
Private Const WSATYPE_NOT_FOUND As Long = (WSABASEERR + 109) 'Class type not found
Private Const WSA_E_NO_MORE As Long = (WSABASEERR + 110)
Private Const WSA_E_CANCELLED As Long = (WSABASEERR + 111)
Private Const WSAEREFUSED As Long = (WSABASEERR + 112)
'Authoritative Answer: Host not found
Private Const WSAHOST_NOT_FOUND As Long = (WSABASEERR + 1001) 'Host not found
'Non-Authoritative: Host not found, or SERVERFAIL
Private Const WSATRY_AGAIN As Long = (WSABASEERR + 1002) 'Non-authoritative host not found
'Non recoverable errors, FORMERR, REFUSED, NOTIMP
Private Const WSANO_RECOVERY As Long = (WSABASEERR + 1003) 'This is a non-recoverable error
'Valid name, no data record of requested type
Private Const WSANO_DATA As Long = (WSABASEERR + 1004) 'Valid name, no data record of requested type

Private Const INVALID_SOCKET As Long = -1& ' Indication of an Invalid Socket
Private Const SOCKET_ERROR As Long = -1&

Private Const INADDR_ANY As Long = &H0 'Used for auto bind of a socket / selects an unused socket (Confirmed)
Private Const INADDR_NONE As Long = &HFFFFFFFF 'Was FFFF (Confirmed) ... Returned address is an error

Private Const AF_UNSPEC As Long = 0 'unspecified
Private Const AF_UNIX As Long = 1 'local to host (pipes, portals)
Private Const AF_INET As Long = 2 'internetwork: UDP, TCP, etc
Private Const AF_IMPLINK As Long = 3 'arpanet imp addresses
Private Const AF_PUP As Long = 4 'pup protocols: e.g. BSP
Private Const AF_CHAOS As Long = 5 'mit CHAOS protocols
Private Const AF_NS As Long = 6 'XEROX NS protocols
Private Const AF_ISO As Long = 7 'ISO protocols
Private Const AF_OSI As Long = AF_ISO 'OSI is ISO
Private Const AF_ECMA As Long = 8 'european computer manufacturers
Private Const AF_DATAKIT As Long = 9 'datakit protocols
Private Const AF_CCITT As Long = 10 'CCITT protocols, X.25 etc
Private Const AF_SNA As Long = 11 'IBM SNA
Private Const AF_DECnet As Long = 12 'DECnet
Private Const AF_DLI As Long = 13 'Direct data link interface
Private Const AF_LAT As Long = 14 'LAT
Private Const AF_HYLINK As Long = 15 'NSC Hyperchannel
Private Const AF_APPLETALK As Long = 16 'AppleTalk
Private Const AF_NETBIOS As Long = 17 'NetBios-style addresses
Private Const AF_MAX As Long = 18

'Confirmed - Maximum queue length specifiable by listen
Private Const SOMAXCONN As Long = 5
'Confirmed flags for recv
'To extract the data from recv - use 0 for flags value (default)
Private Const MSG_OOB As Long = &H1                     'Process out-of-band data
Private Const MSG_PEEK As Long = &H2                    'Peek at incoming message (Probably the only one used !!!)
Private Const MSG_DONTROUTE As Long = &H4               'Send without using routing tables

'Confirmed types
Private Const SOCK_STREAM As Long = 1    'stream socket
Private Const SOCK_DGRAM As Long = 2     'datagram socket
Private Const SOCK_RAW As Long = 3       'raw-protocol interface
Private Const SOCK_RDM As Long = 4       'reliably-delivered message
Private Const SOCK_SEQPACKET As Long = 5 'sequenced packet stream

'Confirmed option level flags (per-socket)
Private Const SOL_SOCKET As Long = &HFFFF& 'Officially the only option for socket level
'Confirmed option flags (per-socket)
Private Const SO_DEBUG As Long = &H1&          'turn on debugging info recording
Private Const SO_ACCEPTCONN As Long = &H2&     'socket has had listen()
Private Const SO_REUSEADDR As Long = &H4&     'allow local address reuse
Private Const SO_KEEPALIVE As Long = &H8&    'keep connections alive (VERY important for future use)
Private Const SO_DONTROUTE As Long = &H10&     'just use interface addresses
Private Const SO_BROADCAST As Long = &H20&    'permit sending of broadcast msgs
Private Const SO_USELOOPBACK As Long = &H40& 'bypass hardware when possible
Private Const SO_LINGER As Long = &H80&      'linger on close if data present
'Private Const SO_DONTLINGER (u_int)(~SO_LINGER)'??? What does this C code mean ??? I believe that this is not really an option for write ... but displays the inverse of SO_LINGER
Private Const SO_OOBINLINE As Long = &H100&    'leave received OOB data in line

'Confirmed additional sock options used by getsockopt API (SO As Long = SockOption)
Private Const SO_SNDBUF As Long = &H1001&    'send buffer size
Private Const SO_RCVBUF As Long = &H1002&    'receive buffer size
Private Const SO_SNDLOWAT As Long = &H1003& 'send low-water mark
Private Const SO_RCVLOWAT As Long = &H1004&  'receive low-water mark
Private Const SO_SNDTIMEO As Long = &H1005&  'send timeout
Private Const SO_RCVTIMEO As Long = &H1006&  'receive timeout
Private Const SO_ERROR As Long = &H1007&    'get error status and clear (Use THIS in stead of WSAGetLastError to return the Socket specific error)
Private Const SO_TYPE As Long = &H1008&     'get socket type

'Confirmed TCP Options
Private Const TCP_NODELAY As Long = &H1

'Confirmed flags to be used with the WSAAsyncSelect() call and on Msg arrival
Private Const FD_READ As Long = &H1
Private Const FD_WRITE As Long = &H2
Private Const FD_OOB As Long = &H4
Private Const FD_ACCEPT As Long = &H8
Private Const FD_CONNECT As Long = &H10
Private Const FD_CLOSE As Long = &H20

' Confirmed ShutDown options
Private Const SD_RECEIVE As Long = &H0
Private Const SD_SEND As Long = &H1
Private Const SD_BOTH As Long = &H2


'Confirmed list of Protocols for use by Socket API call
Private Const IPPROTO_IP As Long = 0 'dummy for IP
Private Const IPPROTO_ICMP As Long = 1 'control message protocol
Private Const IPPROTO_GGP As Long = 2 'gateway^2 (deprecated)
Private Const IPPROTO_TCP As Long = 6 'tcp
Private Const IPPROTO_PUP As Long = 12 'pup
Private Const IPPROTO_UDP As Long = 17 'user datagram protocol
Private Const IPPROTO_IDP As Long = 22 'xns idp
Private Const IPPROTO_ND As Long = 77 'UNOFFICIAL net disk proto
Private Const IPPROTO_RAW As Long = 255 'raw IP packet
Private Const IPPROTO_MAX As Long = 256

Private Const GWL_WNDPROC As Long = (-4)

'Public Const WINSOCK_MESSAGE As Long = 4025 'The only Message type currently used ... not anymore :)
Private Const soxSERVER As Long = 4026& ' This indicates that the Socket is either a Listening Socket, or was created from a Listening Socket, either way, our machine is acting as a Sox Server
Private Const soxCLIENT As Long = 4027& ' This indicates that the Socket is a connection we established to another computer/server, therefore our machine is acting as a Sox Client on this Socket

Private Declare Function apiWSAStartup Lib "WS2_32" Alias "WSAStartup" (ByVal wVersionRequired As Long, lpWSADATA As typWSAData) As Long
Private Declare Function apiWSACleanup Lib "WS2_32" Alias "WSACleanup" () As Long
Private Declare Function apiSocket Lib "WS2_32" Alias "socket" (ByVal af As Long, ByVal s_type As Long, ByVal protocol As Long) As Long
Private Declare Function apiCloseSocket Lib "WS2_32" Alias "closesocket" (ByVal s As Long) As Long
Private Declare Function apiBind Lib "WS2_32" Alias "bind" (ByVal s As Long, addr As typSocketAddr, ByVal namelen As Long) As Long
Private Declare Function apiListen Lib "WS2_32" Alias "listen" (ByVal s As Long, ByVal backlog As Long) As Long
Private Declare Function apiConnect Lib "WS2_32" Alias "connect" (ByVal s As Long, Name As typSocketAddr, ByVal namelen As Long) As Long
Private Declare Function apiAccept Lib "WS2_32" Alias "accept" (ByVal s As Long, addr As typSocketAddr, addrLen As Long) As Long
Private Declare Function apiWSAAsyncSelect Lib "WS2_32" Alias "WSAAsyncSelect" (ByVal s As Long, ByVal hWnd As Long, ByVal wMsg As Long, ByVal lEvent As Long) As Long
Private Declare Function apiRecv Lib "WS2_32" Alias "recv" (ByVal s As Long, buf As Any, ByVal buflen As Long, ByVal flags As Long) As Long
Private Declare Function apiSend Lib "WS2_32" Alias "send" (ByVal s As Long, buf As Any, ByVal buflen As Long, ByVal flags As Long) As Long
Private Declare Function apiGetSockOpt Lib "WS2_32" Alias "getsockopt" (ByVal s As Long, ByVal Level As Long, ByVal optname As Long, optval As Any, optlen As Long) As Long
Private Declare Function apiSetSockOpt Lib "WS2_32" Alias "setsockopt" (ByVal s As Long, ByVal Level As Long, ByVal optname As Long, optval As Any, ByVal optlen As Long) As Long
Private Declare Function apiHToNL Lib "WS2_32" Alias "htonl" (ByVal hostlong As Long) As Long 'Host To Network Long
Private Declare Function apiHToNS Lib "WS2_32" Alias "htons" (ByVal hostshort As Long) As Integer 'Host To Network Short
Private Declare Function apiNToHL Lib "WS2_32" Alias "ntohl" (ByVal netlong As Long) As Long 'Network To Host Long
Private Declare Function apiNToHS Lib "WS2_32" Alias "ntohs" (ByVal netshort As Long) As Integer 'Network To Host Short
Private Declare Function apiIPToNL Lib "WS2_32" Alias "inet_addr" (ByVal cp As String) As Long
Private Declare Function apiNLToIP Lib "WS2_32" Alias "inet_ntoa" (ByVal inn As Long) As Long
Private Declare Function apiGetHostName Lib "WS2_32" Alias "gethostname" (ByVal Name As String, ByVal namelen As Long) As Long
Private Declare Function apiShutDown Lib "WS2_32" Alias "shutdown" (ByVal s As Long, ByVal how As Long) As Long
Private Declare Function WSAGetLastError Lib "WSOCK32" () As Long

Private Declare Function apiCreateWindowEx Lib "user32" Alias "CreateWindowExA" (ByVal dwExStyle As Long, ByVal lpClassName As String, ByVal lpWindowName As String, ByVal dwStyle As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hWndParent As Long, ByVal hMenu As Long, ByVal hInstance As Long, lpParam As Any) As Long
Private Declare Function apiDestroyWindow Lib "user32" Alias "DestroyWindow" (ByVal hWnd As Long) As Long
Private Declare Function apiCallWindowProc Lib "user32" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hWnd As Long, ByVal Msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function apiSetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hWnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long

Private Declare Function apiLStrLen Lib "kernel32" Alias "lstrlenA" (ByVal lpString As Any) As Long
Private Declare Function apiLstrCpy Lib "kernel32" Alias "lstrcpyA" (ByVal lpString1 As String, ByVal lpString2 As Long) As Long
Private Declare Sub apiCopyMemory Lib "kernel32" Alias "RtlMoveMemory" (pDst As Any, pSrc As Any, ByVal ByteLen As Long)

Private WSADATA As typWSAData 'Stores WinSock data on initialization of WinSock 2
Private Sockets() As typSocket
Private Socks As New Collection

Private Sub Class_Initialize()
    If apiWSAStartup(&H101, WSADATA) = SOCKET_ERROR Then
        Call MsgBox("WinSock failed to initialize properly - Error#: " & err.LastDllError) 'Creates an 'application instance' and memory space in the WinSock DLL (MUST be cleaned up later)
    Else
        Let Portal.hWnd = apiCreateWindowEx(0&, "STATIC", "Portal", 0&, 0&, 0&, 0&, 0&, 0&, 0&, App.hInstance, ByVal 0&) 'Create a hidden object to accept our WinSock messages
        If Portal.hWnd = 0 Then
            Call MsgBox("Error: " & err.LastDllError & " on Portal creation.")   'If cleanup failed, does not / cannot raise errors
        Else
            Let Portal.WndProc = apiSetWindowLong(Portal.hWnd, GWL_WNDPROC, AddressOf WindowProc)
            Let Portal.Sockets = -1 ' Initialize our socket count ... NB - WE HAVE NONE, used primarily to Redim the Sockets Array
            ReDim Sockets(0)
        End If
    End If
End Sub

Private Sub Class_Terminate() 'Scaled down version of Terminate code, used purely as failsafe, normally just call Terminate Sub above
    Dim tmpSox As Long
    For tmpSox = 0 To Portal.Sockets
        Call apiShutDown(Sockets(tmpSox).Socket, SD_BOTH)
        Call apiCloseSocket(Sockets(tmpSox).Socket)
    Next tmpSox
    'Correctly replaces/reattaches the origional WindowProc procedure to our 'hidden' handle
    Call apiSetWindowLong(Portal.hWnd, GWL_WNDPROC, Portal.WndProc)
    'This will destroy our hidden object that received all our WinSock API messages
    If apiDestroyWindow(Portal.hWnd) = 0 Then Call MsgBox("Error#: " & err.LastDllError & " on Portal destruction")  'If cleanup failed, does not / cannot raise errors
    If apiWSACleanup = SOCKET_ERROR Then Call MsgBox("WinSock failed to terminate properly, memory leak imminent - Error#: " & err.LastDllError)  'If cleanup failed, does not / cannot raise errors
End Sub

Private Function Accept(inSocket As Long) As Long 'Returns: New Sox Number -- inSocket is the listening WinSocket ...
    #If Debugging = 1 Then
        SendSvrMsg "Accept called!"
    #End If
    Dim tmpSocket As Long, Found As Boolean
    Dim tmpSocketAddr As typSocketAddr 'This stores the details of our new socket/client, including the client IP address
    Let tmpSocket = apiAccept(inSocket, tmpSocketAddr, SOCKADDR_SIZE) 'Accept API returns a valid, random, unused socket for us to use for the new client
    If tmpSocket = INVALID_SOCKET Then 'Accept API may not give us a valid socket eg. when all sockets are full, you may have to add additional error trapping if you believe you will use over 32,767 sockets
        'Since a socket was not commited for the new Connection ... we don't have to close it (Since the socket was never even created)
        Let Accept = INVALID_SOCKET
    Else ' Success, A new connection ... Accept now contains the new Socket number
'        For Accept = 0 To Portal.Sockets ' First search to see if the socket already exists
'            If Sockets(Accept).Socket = tmpSocket Then
'                Found = True
'                Exit For
'            End If
'        Next Accept
        LocalConn = LocalConn + 1
        Accept = UBound(Sockets) + 1
        Socks.Add Accept, CStr(tmpSocket)
        ReDim Preserve Sockets(Accept)
        Portal.Sockets = Portal.Sockets + 1
        #If Debugging = 1 Then
            SendSvrMsg CStr(Portal.Sockets)
        #End If
        Let Sockets(Accept).Socket = tmpSocket
        Let Sockets(Accept).SocketAddr = tmpSocketAddr 'Set the details of the new socket/client
        Let Sockets(Accept).uMsg = soxSERVER  'This is a Client Socket - It has connected to US
        Call RaiseState(Accept, soxConnecting) ' Could possibly leave this on soxDisconnected, and on Select Case State, thurn it on and set it ready to send data (Or set it to connecting)
        Call Sox_Connect(Accept, True)
    End If
End Function

Public Function Bind(LocalPort As Integer, LocalIP As String) As Long
    #If Debugging = 1 Then
        SendSvrMsg "Bind called!"
    #End If
    Dim tmpSocket As Long, DoReAlloc As Boolean
    DoReAlloc = True
    Dim tmpSocketAddr As typSocketAddr
    If LocalPort = 0 Or Len(LocalIP) = 0 Then
        Let Bind = INVALID_SOCKET
    Else
        Let tmpSocketAddr.sin_family = AF_INET
        Let tmpSocketAddr.sin_port = apiHToNS(LocalPort)
        If tmpSocketAddr.sin_port = INVALID_SOCKET Then
            Let Bind = INVALID_SOCKET
        Else
            Let tmpSocketAddr.sin_addr = apiIPToNL(LocalIP) 'If this is Zero, it will assign 0.0.0.0 !!!
            If tmpSocketAddr.sin_addr = INADDR_NONE Then 'If 255.255.255.255 is returned ... we have a problem ... I think :)
                Let Bind = INVALID_SOCKET
            Else
                Let tmpSocket = apiSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP) 'This is where you specify what type of protocol to use and what type of Streaming to use, returns a new socket number 4 us (NB - From here, if any further steps fail after this one succeeds, we must close the socket)
                If tmpSocket = INVALID_SOCKET Then
                    Let Bind = INVALID_SOCKET
                Else
                    If apiBind(tmpSocket, tmpSocketAddr, SOCKADDR_SIZE) = SOCKET_ERROR Then 'Socket Number, Socket Address space / Name, Name Length ...
                        Call apiCloseSocket(tmpSocket)
                        Let Bind = SOCKET_ERROR
                    Else
'                        For Bind = 0 To Portal.Sockets ' First search to see if the socket already exists
'                            If Sockets(Bind).Socket = tmpSocket Then Exit For
'                        Next Bind
                        'If Bind = Portal.Sockets + 1 Then ' If we haven't found an address (Hopefully the only case), Search for an open slot in the array
'                            For Bind = 0 To Portal.Sockets ' First search to see if the socket already exists
'                                If Sockets(Bind).Socket = soxDisconnected Then Exit For ' Found an open Socket
'                            Next Bind
'                            If Bind = Portal.Sockets + 1 Then ' If we haven't found an address (Hopefully the only case), Search for an open slot in the array
'                                If Bind < UBound(Sockets) Then
'                                    DoReAlloc = False
'                                End If
'                                If DoReAlloc Then ReDim Preserve Sockets(Bind) As typSocket
'                                Let Portal.Sockets = Bind
                                Bind = UBound(Sockets) + 1
                                Socks.Add Bind, CStr(tmpSocket)
                                ReDim Preserve Sockets(Bind)
                                Portal.Sockets = Portal.Sockets + 1
                                #If Debugging = 1 Then
                                    SendSvrMsg CStr(Portal.Sockets)
                                #End If
                                
                        'End If
                        Let Sockets(Bind).Socket = tmpSocket
                        Let Sockets(Bind).SocketAddr = tmpSocketAddr 'Set the details of the new socket/client
                        Call RaiseState(Bind, soxBound)
                    End If
                End If
            End If
        End If
    End If
End Function

'At the moment, we are closing all the sockets in their respectful areas, eg. Connect closes it's own sockets, we may in future need to close all sockets here (Cannot do this as Async will fail and the socket will not be closed properly, Create another private Function to do this)
Public Function CloseIt(insox As Long) As Long 'OCX Returns # of errors in collection, so should we :)))
  #If Debugging = 1 Then
    SendSvrMsg "CloseIt called!"
  #End If
'    If insox < Ports Then  ' Detect out of Range of our Array ...
'        Let CloseIt = INVALID_SOCKET
'        SendSvrMsg "Closure of socket " & insox & " denied!"
'    Else
        If apiGetSockOpt(Sockets(insox).Socket, SOL_SOCKET, soxSO_ERROR, CloseIt, 4) = SOCKET_ERROR Then
              Let CloseIt = SOCKET_ERROR
        Else
            If apiShutDown(Sockets(insox).Socket, SD_BOTH) = SOCKET_ERROR Then
                Let CloseIt = SOCKET_ERROR
            Else
                TerminateSocket Sockets(insox).Socket
                Call RaiseState(insox, soxClosing)
                With Sockets(insox)
                    .Socket = 0
                    .State = 0
                    .uMsg = 0
                End With
            End If
        End If
    'End If
End Function

Public Function Connect(Optional RemoteHost As String, Optional RemotePort As Integer) As Long 'Returns the new Sox Number / SOCKET_ERROR On Error
    #If Debugging = 1 Then
        SendSvrMsg "Connect called!"
    #End If
    If Not IsIP(RemoteHost) Then
        RemoteHost = NameToAddress(RemoteHost)
    End If
    Dim tmpSocket As Long
    Dim tmpSocketAddr As typSocketAddr
    Let tmpSocketAddr.sin_family = AF_INET
    Let tmpSocketAddr.sin_port = apiHToNS(RemotePort) ' apiHToNS(RemotePort)
    If tmpSocketAddr.sin_port = INVALID_SOCKET Then
        Let Connect = INVALID_SOCKET
    Else
        Let tmpSocketAddr.sin_addr = apiIPToNL(RemoteHost) 'If this is Zero, it will assign 0.0.0.0 !!!
        If tmpSocketAddr.sin_addr = INADDR_NONE Then 'If 255.255.255.255 is returned ... we have a problem ... I think :)
            Let Connect = INVALID_SOCKET
        Else
            Let tmpSocket = apiSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP) 'This is where you specify what type of protocol to use and what type of Streaming to use, returns a new socket number 4 us (NB - From here, if any further steps fail after this one succeeds, we must close the socket)
            If tmpSocket = INVALID_SOCKET Then
                Let Connect = INVALID_SOCKET
            Else
                If apiConnect(tmpSocket, tmpSocketAddr, SOCKADDR_SIZE) = SOCKET_ERROR Then
                    Call apiCloseSocket(tmpSocket)
                    Let Connect = SOCKET_ERROR
                Else
                    If apiWSAAsyncSelect(tmpSocket, Portal.hWnd, ByVal soxCLIENT, ByVal FD_ACCEPT Or FD_CLOSE Or FD_CONNECT Or FD_READ Or FD_WRITE) = SOCKET_ERROR Then ' Reassign this Socket to Send and Receive on the DATA channel
                        Call apiCloseSocket(tmpSocket)
                        Let Connect = SOCKET_ERROR
                    Else
'                        For Connect = 0 To Portal.Sockets ' First search to see if the socket already exists
'                            If Sockets(Connect).Socket = tmpSocket Then Exit For
'                        Next Connect
'                        If Connect = Portal.Sockets + 1 Then ' If we haven't found an address (Hopefully the only case), Search for an open slot in the array
'                            For Connect = 0 To Portal.Sockets ' First search to see if the socket already exists
'                                If Sockets(Connect).Socket = soxDisconnected Then Exit For ' Found an open Socket
'                            Next Connect
'                            If Connect = Portal.Sockets + 1 Then ' If we haven't found an address (Hopefully the only case), Search for an open slot in the array
'                                ReDim Preserve Sockets(Connect) As typSocket
'                                Let Portal.Sockets = Connect
'                            End If
'                        End If
                        Connect = UBound(Sockets) + 1
                        Socks.Add Connect, CStr(tmpSocket)
                        ReDim Preserve Sockets(Connect)
                        Portal.Sockets = Portal.Sockets + 1
                        #If Debugging = 1 Then
                            SendSvrMsg CStr(Portal.Sockets)
                        #End If
                        
                        Let Sockets(Connect).Socket = tmpSocket
                        Let Sockets(Connect).SocketAddr = tmpSocketAddr 'Set the details of the new socket/client
                        Let Sockets(Connect).uMsg = soxSERVER ' This is a Server connection - We have connected to it (Could even be another Client computer but the fact is we connected to it)
'                        Let Sockets(Connect).DataLen = -1
'                        Erase Sockets(Connect).Data
                        Call RaiseState(Connect, soxConnecting)
                    End If
                End If
            End If
        End If
    End If
End Function

Private Sub GetData(insox As Long) ' Extracts data from the WinSock Recv buffers and places it in our local buffer (data() array)
'On Error Resume Next
#If Debugging = 1 Then
    SendSvrMsg "GetData called!"
#End If
Dim I As Long
    Dim tmpRecv As Long 'Holds how much data we actually received
    tmpRecv = 1
    Dim tmpBuffer() As Byte, InData$, buf$ 'This buffer could be optimized for small data, eg. A chat program, if you set it's size, to say 255 (256 in total), it could retrieve data faster
        ' First we will disable further notification of FD_READ, because if we extract data with the Recv function, WinSock API posts ANOTHER FD_READ notification to say there's more ...
        ' This is a valid (dare I say recommended) procedure according to WinSock API documentation on MSDN
        Call apiWSAAsyncSelect(Sockets(insox).Socket, Portal.hWnd, ByVal Sockets(insox).uMsg, 0&)   ' Reassign this Socket to Send and Receive on the DATA channel
            If Sockets(insox).State = soxConnected Then Call RaiseState(insox, soxDataRecv)
            Do While tmpRecv > 0
                ReDim tmpBuffer(0 To 511) As Byte
                tmpRecv = apiRecv(Sockets(insox).Socket, tmpBuffer(0), 512, 0)
                Select Case tmpRecv
                    Case 0 ' The Socket was Gracefully closed
                        Call Sox_Close(insox)
                    Case -1
                        RaiseError insox, WSAGetLastError, "GetData", "Rec"
                    Case Else
                        buf = StrConv(tmpBuffer, vbUnicode)
                        I = InStr(1, buf, vbNullChar)
                        If I = 0 Then
                            InData = InData & buf
                        Else
                            InData = InData & Left$(buf, I)
                        End If
                End Select
            Loop
'-------------- CUT BY DILL BECAUSE ABOVE IS ALL-SUFFICIENT --------------
    apiWSAAsyncSelect Sockets(insox).Socket, Portal.hWnd, ByVal Sockets(insox).uMsg, ByVal FD_CLOSE Or FD_READ Or FD_WRITE
Call Sox_DataArrival(insox, InData)
End Sub

'Creates a socket and sets it in listen mode. This method works only for TCP connections
Public Function Listen(inAddress As String, inPort As Integer) As Long   'Returns Sox number / SOCKET_ERROR On Error
    #If Debugging = 1 Then
        SendSvrMsg "Listen called!"
    #End If
    Dim tmpSocket As Long
    Dim tmpSocketAddr As typSocketAddr
    Let tmpSocketAddr.sin_family = AF_INET
    Let tmpSocketAddr.sin_port = apiHToNS(inPort)
    If tmpSocketAddr.sin_port = INVALID_SOCKET Then
        Let Listen = INVALID_SOCKET
    Else
        Let tmpSocketAddr.sin_addr = apiIPToNL(inAddress) 'If this is Zero, it will assign 0.0.0.0 !!!
        If tmpSocketAddr.sin_addr = INADDR_NONE Then 'If 255.255.255.255 is returned ... we have a problem ... I think :)
            Let Listen = INVALID_SOCKET
        Else
            Let tmpSocket = apiSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP) 'This is where you specify what type of protocol to use and what type of Streaming to use, returns a new socket number 4 us (NB - From here, if any further steps fail after this one succeeds, we must close the socket)
            If tmpSocket = INVALID_SOCKET Then
                Let Listen = INVALID_SOCKET
            Else
                If apiBind(tmpSocket, tmpSocketAddr, SOCKADDR_SIZE) = SOCKET_ERROR Then 'Socket Number, Socket Address space / Name, Name Length ...
                    Call apiCloseSocket(tmpSocket)
                    Let Listen = SOCKET_ERROR
                Else
                    If apiListen(ByVal tmpSocket, ByVal SOMAXCONN) = SOCKET_ERROR Then ' 5 = Maximum connections
                        Call apiCloseSocket(tmpSocket)
                        Let Listen = SOCKET_ERROR
                    Else
                        If apiWSAAsyncSelect(tmpSocket, Portal.hWnd, ByVal soxSERVER, ByVal FD_CONNECT Or FD_READ Or FD_ACCEPT Or FD_CLOSE Or FD_WRITE) = SOCKET_ERROR Then ' Reassign this Socket to Send and Receive on the DATA channel
                            Call apiCloseSocket(tmpSocket)
                            Let Listen = SOCKET_ERROR
                        Else
'                            For Listen = 0 To Portal.Sockets ' First search to see if the socket already exists
'                                If Sockets(Listen).Socket = tmpSocket Then Exit For
'                            Next Listen
'                            If Listen = Portal.Sockets + 1 Then ' If we haven't found an address (Hopefully the only case), Search for an open slot in the array
'                                For Listen = 0 To Portal.Sockets ' First search to see if the socket already exists
'                                    If Sockets(Listen).Socket = soxDisconnected Then Exit For ' Found an open Socket
'                                Next Listen
'                                If Listen = Portal.Sockets + 1 Then ' If we haven't found an address (Hopefully the only case), Search for an open slot in the array
'                                    ReDim Preserve Sockets(Listen) As typSocket
'                                    Let Portal.Sockets = Listen
'                                End If
'                            End If
                            Listen = UBound(Sockets) + 1
                            Socks.Add Listen, CStr(tmpSocket)
                            ReDim Preserve Sockets(Listen)
                            Portal.Sockets = Portal.Sockets + 1
                            #If Debugging = 1 Then
                                SendSvrMsg CStr(Portal.Sockets)
                            #End If
                            
                            Let Sockets(Listen).Socket = tmpSocket
                            Let Sockets(Listen).SocketAddr = tmpSocketAddr 'Set the details of the new socket/client
                            Let Sockets(Listen).uMsg = soxSERVER
'                            Let Sockets(Listen).DataLen = -1
'                            Erase Sockets(Listen).Data
                            Call RaiseState(Listen, soxListening)
                        End If
                    End If
                End If
            End If
        End If
    End If
End Function

Private Function WinSockEvent(ByVal lParam As Long) As Integer 'WSAGETSELECTEVENT
    If (lParam And &HFFFF&) > &H7FFF Then
        Let WinSockEvent = (lParam And &HFFFF&) - &H10000
    Else
        Let WinSockEvent = lParam And &HFFFF&
    End If
End Function

Private Function WinSockError(ByVal lParam As Long) As Integer 'WSAGETSELECTERROR
    Let WinSockError = (lParam And &HFFFF0000) \ &H10000
End Function

Private Sub RaiseState(insox As Long, inState As enmSoxState)
    Let Sockets(insox).State = inState
    #If Debugging = 1 Then
        SendSvrMsg "State changed to: " & inState
    #End If
End Sub

Public Sub Hook()
    If Portal.WndProc = 0 Then Let Portal.WndProc = apiSetWindowLong(Portal.hWnd, GWL_WNDPROC, AddressOf WindowProc)
End Sub
Public Sub Unhook()
    Call apiSetWindowLong(Portal.hWnd, GWL_WNDPROC, Portal.WndProc)
    Let Portal.WndProc = 0
End Sub

Private Function StringFromPointer(ByVal lPointer As Long) As String
    Let StringFromPointer = Space$(apiLStrLen(ByVal lPointer))
    Call apiLstrCpy(ByVal StringFromPointer, ByVal lPointer)
End Function

Public Function WndProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
    'Const Procedure As String = "WndProc"
    Select Case uMsg
        Case soxSERVER
            Select Case WinSockEvent(lParam)
                Case FD_ACCEPT
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Server received: FD_ACCEPT")
                    #End If
                    Select Case WinSockError(lParam)
                        Case 0: Accept (wParam)
                        Case Else: Call RaiseError(IsInSox(wParam), WinSockError(lParam), "WndProc", "On FD_ACCEPT -- lParam: " & lParam)
                    End Select
                    #If Debugging = 1 Then
                        Case FD_CONNECT
                            Call RaiseStatus(IsInSox(wParam), "WndProc", "Server received: FD_CONNECT")
                    #End If
                Case FD_READ
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Server received: FD_READ")
                    #End If
                    Call GetData(IsInSox(wParam))
                Case FD_WRITE
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Server received: FD_WRITE") ' A Server Client is ready to Send
                    #End If
                    Select Case WinSockError(lParam)
                        Case 0
                            Select Case Sockets(IsInSox(wParam)).State
                                Case soxConnecting
                                    Call RaiseState(IsInSox(wParam), soxConnected)
                                Case soxDataSend: Let Sockets(IsInSox(wParam)).State = soxConnected
                            End Select
                        Case Else: Call RaiseError(IsInSox(wParam), WinSockError(lParam), "WndProc", "On FD_WRITE -- lParam: " & lParam)
                    End Select
                Case FD_CLOSE
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Server received: FD_CLOSE")
                    #End If
                    Call Sox_Close(IsInSox(wParam))
                    Select Case WinSockError(lParam)
                        Case 0
                            Select Case Sockets(IsInSox(wParam)).State
                                Case soxClosing: Call ShutDown(IsInSox(wParam))
                                Case Else
                                    Call CloseIt(IsInSox(wParam))
                                    Call ShutDown(IsInSox(wParam))
                            End Select
                        Case Else
                            Call ShutDown(IsInSox(wParam))
                            Call RaiseError(IsInSox(wParam), WinSockError(lParam), "WndProc", "On FD_CLOSE -- lParam: " & lParam)
                    End Select
                Case Else
            End Select
        Case soxCLIENT
            Select Case WinSockEvent(lParam)
                Case FD_ACCEPT
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Client received: FD_ACCEPT")
                    #End If
                    LocalConn = LocalConn + 1
                    Call Sox_Connect(IsInSox(wParam), False)
                Case FD_CLOSE
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Client received: FD_CLOSE")
                    #End If
                    Call Sox_Close(IsInSox(wParam))
                    Select Case WinSockError(lParam)
                        Case 0
                            Select Case Sockets(IsInSox(wParam)).State
                                Case soxClosing: Call ShutDown(IsInSox(wParam))
                                Case Else
                                    Call CloseIt(IsInSox(wParam))
                                    Call ShutDown(IsInSox(wParam))
                            End Select
                        Case Else
                            Call ShutDown(IsInSox(wParam))
                            Call RaiseError(IsInSox(wParam), WinSockError(lParam), "WndProc", "On FD_CLOSE -- lParam: " & lParam)
                    End Select
                Case FD_CONNECT
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Client received: FD_CONNECT")
                    #End If
                    Call Sox_Connect(IsInSox(wParam), False)
                Case FD_READ
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Client received: FD_READ")
                    #End If
                    Call GetData(IsInSox(wParam))
                Case FD_WRITE
                    #If Debugging = 1 Then
                        Call RaiseStatus(IsInSox(wParam), "WndProc", "Client received: FD_WRITE")
                    #End If
                    Select Case WinSockError(lParam)
                        Case 0
                            Select Case Sockets(IsInSox(wParam)).State
                                Case soxConnecting
                                    Call RaiseState(IsInSox(wParam), soxConnected)
                                    Call Sox_Connect(IsInSox(wParam), False)
                                Case soxDataSend: Let Sockets(IsInSox(wParam)).State = soxConnected
                            End Select
                        Case Else: Call RaiseError(IsInSox(wParam), WinSockError(lParam), "WndProc", "On FD_WRITE -- lParam: " & lParam)
                    End Select
                Case Else
            End Select
        Case Else: Let WndProc = apiCallWindowProc(Portal.WndProc, hWnd, uMsg, wParam, lParam)
    End Select
End Function

Public Function IsInSox(inSocket As Long) As Long ' Returns the Sockets() address of a WinSock Socket
On Error Resume Next
IsInSox = Socks(CStr(inSocket))
If IsInSox = 0 Then IsInSox = -1
End Function

Public Function SetOption(insox As Long, inOption As enmSoxOptions, inValue As Long) As Long
        Select Case inOption
            Case soxSO_TCP_NODELAY
                If apiSetSockOpt(Sockets(insox).Socket, IPPROTO_TCP, Not inOption, inValue, 4) = SOCKET_ERROR Then
                    Let SetOption = SOCKET_ERROR
                End If
            Case Else
                If apiSetSockOpt(Sockets(insox).Socket, SOL_SOCKET, inOption, inValue, 4) = SOCKET_ERROR Then
                    Let SetOption = SOCKET_ERROR
                End If
        End Select
End Function

Public Function GetOption(insox As Long, inOption As enmSoxOptions) As Long
        Select Case inOption
            Case soxSO_TCP_NODELAY
                If apiGetSockOpt(Sockets(insox).Socket, IPPROTO_TCP, Not inOption, GetOption, 4) = SOCKET_ERROR Then
                    Let GetOption = SOCKET_ERROR
                End If
            Case Else
                If apiGetSockOpt(Sockets(insox).Socket, SOL_SOCKET, inOption, GetOption, 4) = SOCKET_ERROR Then
                    Let GetOption = SOCKET_ERROR
                End If
        End Select
End Function

Public Function SocketHandle(insox As Long) As Long
    Let SocketHandle = Sockets(insox).Socket
End Function

Public Function State(insox As Long) As enmSoxState
    Let State = Sockets(insox).State
End Function

Public Function Address(insox As Long) As String ' Returns the address used by a Socket (Either Local or Remote)
    Let Address = StringFromPointer(apiNLToIP(Sockets(insox).SocketAddr.sin_addr))
End Function
Public Function Port(insox As Long) As Long
    Let Port = apiNToHS(Sockets(insox).SocketAddr.sin_port)
End Function

Private Sub ShutDown(insox As Long)
    #If Debugging = 1 Then
        SendSvrMsg "ShutDown called!"
    #End If
        If apiWSAAsyncSelect(Sockets(insox).Socket, Portal.hWnd, ByVal FD_CLOSE, 0&) <> SOCKET_ERROR Then       'FD_READ Or FD_WRITE Or FD_CLOSE Or FD_ACCEPT
            If apiCloseSocket(Sockets(insox).Socket) <> SOCKET_ERROR Then  'I can't get the API that checks the current status of the socket to work :(((
                TerminateSocket Sockets(insox).Socket
                With Sockets(insox)
                    .Socket = 0
                    .State = 0
                    .uMsg = 0
                End With
                Call RaiseState(insox, soxDisconnected)
                Call Sox_Close(insox)
            End If
        End If
End Sub

Private Sub RaiseError(insox As Long, inCode As Long, inProcedure As String, inSnipet As String)   'Returns EXACTLY the same value as inError but raises the corresponding event if this is an error
    #If Debugging = 1 Then
        SendSvrMsg "error..." & inSnipet & " " & inProcedure
    #End If
    Select Case inCode
        Case WSABASEERR: Call Sox_Error(insox, inCode, "General WinSock subsystem failure", inProcedure, inSnipet) 'Just sounds cool :)))
        Case WSAEINTR: Call Sox_Error(insox, inCode, "Interrupted function call", inProcedure, inSnipet)
        Case WSAEBADF: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSAEACCES: Call Sox_Error(insox, inCode, "Permission Denied", inProcedure, inSnipet)
        Case WSAEFAULT: Call Sox_Error(insox, inCode, "Bad address", inProcedure, inSnipet)
        Case WSAEINVAL: Call Sox_Error(insox, inCode, "Invalid argument", inProcedure, inSnipet)
        Case WSAEMFILE: Call Sox_Error(insox, inCode, "Too many open files", inProcedure, inSnipet)
        'Case WSAEWOULDBLOCK: Call Sox_Error(insox, inCode, "Resource temporarily unavailable", inProcedure, inSnipet)
        Case WSAEINPROGRESS: Call Sox_Error(insox, inCode, "Operation now in progress", inProcedure, inSnipet)
        Case WSAEALREADY: Call Sox_Error(insox, inCode, "Operation already in progress", inProcedure, inSnipet)
        Case WSAENOTSOCK: Call Sox_Error(insox, inCode, "Socket operation on non-socket", inProcedure, inSnipet)
        Case WSAEDESTADDRREQ: Call Sox_Error(insox, inCode, "Destination address required", inProcedure, inSnipet)
        Case WSAEMSGSIZE: Call Sox_Error(insox, inCode, "Message too long", inProcedure, inSnipet)
        Case WSAEPROTOTYPE: Call Sox_Error(insox, inCode, "Protocol wrong type for socket", inProcedure, inSnipet)
        Case WSAENOPROTOOPT: Call Sox_Error(insox, inCode, "Bad protocol option", inProcedure, inSnipet)
        Case WSAEPROTONOSUPPORT: Call Sox_Error(insox, inCode, "Protocol not supported", inProcedure, inSnipet)
        Case WSAESOCKTNOSUPPORT: Call Sox_Error(insox, inCode, "Socket type not supported", inProcedure, inSnipet)
        Case WSAEOPNOTSUPP: Call Sox_Error(insox, inCode, "Operation not supported", inProcedure, inSnipet)
        Case WSAEPFNOSUPPORT: Call Sox_Error(insox, inCode, "Protocol family not supported", inProcedure, inSnipet)
        Case WSAEAFNOSUPPORT: Call Sox_Error(insox, inCode, "Address family not supported by protocol family", inProcedure, inSnipet)
        Case WSAEADDRINUSE: Call Sox_Error(insox, inCode, "Address already in use", inProcedure, inSnipet)
        Case WSAEADDRNOTAVAIL: Call Sox_Error(insox, inCode, "Cannot assign requested address", inProcedure, inSnipet)
        Case WSAENETDOWN: Call Sox_Error(insox, inCode, "Network is down", inProcedure, inSnipet)
        Case WSAENETUNREACH: Call Sox_Error(insox, inCode, "Network is unreachable", inProcedure, inSnipet)
        Case WSAENETRESET: Call Sox_Error(insox, inCode, "Network dropped connection on reset", inProcedure, inSnipet)
        Case WSAECONNABORTED: Call Sox_Error(insox, inCode, "Software caused connection abort", inProcedure, inSnipet)
        Case WSAECONNRESET: Call Sox_Error(insox, inCode, "Connection reset by peer", inProcedure, inSnipet)
        Case WSAENOBUFS: Call Sox_Error(insox, inCode, "No buffer space available", inProcedure, inSnipet)
        Case WSAEISCONN: Call Sox_Error(insox, inCode, "Socket is already connected", inProcedure, inSnipet)
        Case WSAENOTCONN: Call Sox_Error(insox, inCode, "Socket is not connected", inProcedure, inSnipet)
        Case WSAESHUTDOWN: Call Sox_Error(insox, inCode, "Cannot send after socket shutdown", inProcedure, inSnipet)
        Case WSAETOOMANYREFS: Call Sox_Error(insox, inCode, "Too many references: can't splice", inProcedure, inSnipet)  ' UnConfirmed Description
        Case WSAETIMEDOUT: Call Sox_Error(insox, inCode, "Connection timed out", inProcedure, inSnipet)
        Case WSAECONNREFUSED: Call Sox_Error(insox, inCode, "Connection refused", inProcedure, inSnipet)
        Case WSAELOOP: Call Sox_Error(insox, inCode, "Too many levels of symbolic links", inProcedure, inSnipet)  ' UnConfirmed Description
        Case WSAENAMETOOLONG: Call Sox_Error(insox, inCode, "File name too long", inProcedure, inSnipet)  ' UnConfirmed Description
        Case WSAEHOSTDOWN: Call Sox_Error(insox, inCode, "Host is down", inProcedure, inSnipet)
        Case WSAEHOSTUNREACH: Call Sox_Error(insox, inCode, "No route to host", inProcedure, inSnipet)
        Case WSAENOTEMPTY: Call Sox_Error(insox, inCode, "Directory not empty", inProcedure, inSnipet)  ' UnConfirmed Description
        Case WSAEPROCLIM: Call Sox_Error(insox, inCode, "Too many processes", inProcedure, inSnipet)
        Case WSAEUSERS: Call Sox_Error(insox, inCode, "Too many users", inProcedure, inSnipet)  ' UnConfirmed Description
        Case WSAEDQUOT: Call Sox_Error(insox, inCode, "Disk quota exceeded", inProcedure, inSnipet)  ' UnConfirmed Description
        Case WSAESTALE: Call Sox_Error(insox, inCode, "Stale NFS file handle", inProcedure, inSnipet) ' UnConfirmed Description
        Case WSAEREMOTE: Call Sox_Error(insox, inCode, "Too many levels of remote in path", inProcedure, inSnipet)  ' UnConfirmed Description
        Case WSASYSNOTREADY: Call Sox_Error(insox, inCode, "Network subsystem is unavailable", inProcedure, inSnipet)
        Case WSAVERNOTSUPPORTED: Call Sox_Error(insox, inCode, "WinSock.DLL version out of range", inProcedure, inSnipet)
        Case WSANOTINITIALISED: Call Sox_Error(insox, inCode, "Successful WSAStartup not yet performed", inProcedure, inSnipet)
        Case WSAEDISCON1: Call Sox_Error(insox, inCode, "Graceful shutdown in progress", inProcedure, inSnipet)
        Case WSAEDISCON2: Call Sox_Error(insox, inCode, "Graceful shutdown in progress", inProcedure, inSnipet)
        Case WSAENOMORE: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSAECANCELLED: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSAEINVALIDPROCTABLE: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSAEINVALIDPROVIDER: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSAEPROVIDERFAILEDINIT: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSASYSCALLFAILURE: Call Sox_Error(insox, inCode, "System call failure", inProcedure, inSnipet)
        Case WSASERVICE_NOT_FOUND: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSATYPE_NOT_FOUND: Call Sox_Error(insox, inCode, "Class type not found", inProcedure, inSnipet)
        Case WSA_E_NO_MORE: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSA_E_CANCELLED: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSAEREFUSED: Call Sox_Error(insox, inCode, "Unknown", inProcedure, inSnipet) ' Unknown
        Case WSAHOST_NOT_FOUND: Call Sox_Error(insox, inCode, "Host not found", inProcedure, inSnipet)
        Case WSATRY_AGAIN: Call Sox_Error(insox, inCode, "Non-authoritative host not found", inProcedure, inSnipet)
        Case WSANO_RECOVERY: Call Sox_Error(insox, inCode, "This is a non-recoverable error", inProcedure, inSnipet)
        Case WSANO_DATA: Call Sox_Error(insox, inCode, "Valid name, no data record of requested type", inProcedure, inSnipet)
        'Case Else: Call Sox_Error(insox, inCode, "Unrecognized WinSock error", inProcedure, inSnipet)
    End Select
End Sub
#If Debugging = 1 Then
    Private Sub RaiseStatus(insox As Long, inProcedure As String, inStatus As String)
        SendSvrMsg inStatus
    End Sub
#End If

Public Sub TerminateSocket(hSocket As Long)
On Error Resume Next
Call apiShutDown(hSocket, SD_BOTH)
Call apiCloseSocket(hSocket)
Dim index&
index = Socks(CStr(hSocket))
If index > 0 Then
    Socks.Remove CStr(hSocket)
    LocalConn = LocalConn - 1
End If
End Sub
