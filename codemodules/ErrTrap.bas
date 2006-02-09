Attribute VB_Name = "modErrTrap"
'ignitionServer is (C)  Keith Gable and Nigel Jones.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@silentsoft.net>
'                     Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
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

Private Const EXCEPTION_CONTINUE_EXECUTION = -1
Private Const EXCEPTION_CONTINUE_SEARCH = 0
Private Const EXCEPTION_EXECUTE_HANDLER = 1
Private Const EXCEPTION_MAXIMUM_PARAMETERS = 15

Private Type CONTEXT
  FltF0 As Double
  FltF1 As Double
  FltF2 As Double
  FltF3 As Double
  FltF4 As Double
  FltF5 As Double
  FltF6 As Double
  FltF7 As Double
  FltF8 As Double
  FltF9 As Double
  FltF10 As Double
  FltF11 As Double
  FltF12 As Double
  FltF13 As Double
  FltF14 As Double
  FltF15 As Double
  FltF16 As Double
  FltF17 As Double
  FltF18 As Double
  FltF19 As Double
  FltF20 As Double
  FltF21 As Double
  FltF22 As Double
  FltF23 As Double
  FltF24 As Double
  FltF25 As Double
  FltF26 As Double
  FltF27 As Double
  FltF28 As Double
  FltF29 As Double
  FltF30 As Double
  FltF31 As Double

  IntV0 As Double
  IntT0 As Double
  IntT1 As Double
  IntT2 As Double
  IntT3 As Double
  IntT4 As Double
  IntT5 As Double
  IntT6 As Double
  IntT7 As Double
  IntS0 As Double
  IntS1 As Double
  IntS2 As Double
  IntS3 As Double
  IntS4 As Double
  IntS5 As Double
  IntFp As Double
  IntA0 As Double
  IntA1 As Double
  IntA2 As Double
  IntA3 As Double
  IntA4 As Double
  IntA5 As Double
  IntT8 As Double
  IntT9 As Double
  IntT10 As Double
  IntT11 As Double
  IntRa As Double
  IntT12 As Double
  IntAt As Double
  IntGp As Double
  IntSp As Double
  IntZero As Double

  Fpcr As Double
  SoftFpcr As Double

  Fir As Double
  Psr As Long

  ContextFlags As Long
  Fill(4) As Long
End Type

Private Type EXCEPTION_RECORD
    ExceptionCode As Long
    ExceptionFlags As Long
    pExceptionRecord As Long
    ExceptionAddress As Long
    NumberParameters As Long
    ExceptionInformation(EXCEPTION_MAXIMUM_PARAMETERS) As Long
End Type

Private Type EXCEPTION_DEBUG_INFO
        pExceptionRecord As EXCEPTION_RECORD
        dwFirstChance As Long
End Type

Private Type EXCEPTION_POINTERS
    pExceptionRecord As EXCEPTION_RECORD
    ContextRecord As CONTEXT
End Type

Private Const EXCEPTION_ACCESS_VIOLATION = &HC0000005
Private Const EXCEPTION_DATATYPE_MISALIGNMENT = &H80000002
Private Const EXCEPTION_BREAKPOINT = &H80000003
Private Const EXCEPTION_SINGLE_STEP = &H80000004
Private Const EXCEPTION_ARRAY_BOUNDS_EXCEEDED = &HC000008C
Private Const EXCEPTION_FLT_DENORMAL_OPERAND = &HC000008D
Private Const EXCEPTION_FLT_DIVIDE_BY_ZERO = &HC000008E
Private Const EXCEPTION_FLT_INEXACT_RESULT = &HC000008F
Private Const EXCEPTION_FLT_INVALID_OPERATION = &HC0000090
Private Const EXCEPTION_FLT_OVERFLOW = &HC0000091
Private Const EXCEPTION_FLT_STACK_CHECK = &HC0000092
Private Const EXCEPTION_FLT_UNDERFLOW = &HC0000093
Private Const EXCEPTION_INT_DIVIDE_BY_ZERO = &HC0000094
Private Const EXCEPTION_INT_OVERFLOW = &HC0000095
Private Const EXCEPTION_PRIVILEGED_INSTRUCTION = &HC0000096
Private Const EXCEPTION_IN_PAGE_ERROR = &HC0000006
Private Const EXCEPTION_ILLEGAL_INSTRUCTION = &HC000001D
Private Const EXCEPTION_NONCONTINUABLE_EXCEPTION = &HC0000025
Private Const EXCEPTION_STACK_OVERFLOW = &HC00000FD
Private Const EXCEPTION_INVALID_DISPOSITION = &HC0000026
Private Const EXCEPTION_GUARD_PAGE_VIOLATION = &H80000001
Private Const EXCEPTION_INVALID_HANDLE = &HC0000008
Private Const EXCEPTION_CONTROL_C_EXIT = &HC000013A

Public m_Description As String
Public m_Number As Long

Private Declare Function SetUnhandledExceptionFilter Lib "kernel32" (ByVal lpTopLevelExceptionFilter As Long) As Long
Private Declare Sub CopyExceptionRecord Lib "kernel32" Alias "RtlMoveMemory" (pDest As EXCEPTION_RECORD, ByVal LPEXCEPTION_RECORD As Long, ByVal lngBytes As Long)

Private Function GetExceptionText(ByVal ExceptionCode As Long) As String
  Dim strExceptionString As String
  
  Select Case ExceptionCode
    Case EXCEPTION_ACCESS_VIOLATION
      strExceptionString = "Access Violation"
    Case EXCEPTION_DATATYPE_MISALIGNMENT
      strExceptionString = "Data Type Misalignment"
    Case EXCEPTION_BREAKPOINT
      strExceptionString = "Breakpoint"
    Case EXCEPTION_SINGLE_STEP
      strExceptionString = "Single Step"
    Case EXCEPTION_ARRAY_BOUNDS_EXCEEDED
      strExceptionString = "Array Bounds Exceeded"
    Case EXCEPTION_FLT_DENORMAL_OPERAND
      strExceptionString = "Float Denormal Operand"
    Case EXCEPTION_FLT_DIVIDE_BY_ZERO
      strExceptionString = "Divide By Zero"
    Case EXCEPTION_FLT_INEXACT_RESULT
      strExceptionString = "Floating Point Inexact Result"
    Case EXCEPTION_FLT_INVALID_OPERATION
      strExceptionString = "Invalid Operation"
    Case EXCEPTION_FLT_OVERFLOW
      strExceptionString = "Float Overflow"
    Case EXCEPTION_FLT_STACK_CHECK
      strExceptionString = "Float Stack Check"
    Case EXCEPTION_FLT_UNDERFLOW
      strExceptionString = "Float Underflow"
    Case EXCEPTION_INT_DIVIDE_BY_ZERO
      strExceptionString = "Integer Divide By Zero"
    Case EXCEPTION_INT_OVERFLOW
      strExceptionString = "Integer Overflow"
    Case EXCEPTION_PRIVILEGED_INSTRUCTION
      strExceptionString = "Privileged Instruction"
    Case EXCEPTION_IN_PAGE_ERROR
      strExceptionString = "In Page Error"
    Case EXCEPTION_ILLEGAL_INSTRUCTION
      strExceptionString = "Illegal Instruction"
    Case EXCEPTION_NONCONTINUABLE_EXCEPTION
      strExceptionString = "Non Continuable Exception"
    Case EXCEPTION_STACK_OVERFLOW
      strExceptionString = "Stack Overflow"
    Case EXCEPTION_INVALID_DISPOSITION
      strExceptionString = "Invalid Disposition"
    Case EXCEPTION_GUARD_PAGE_VIOLATION
      strExceptionString = "Guard Page Violation"
    Case EXCEPTION_INVALID_HANDLE
      strExceptionString = "Invalid Handle"
    Case EXCEPTION_CONTROL_C_EXIT
      strExceptionString = "Control-C Exit"
    Case Else
      strExceptionString = "Unknown (&H" & Right$("00000000" & Hex$(ExceptionCode), 8) & ")"
  End Select
  m_Number = ExceptionCode
  GetExceptionText = strExceptionString
End Function

Public Function ExceptionFilter(ByRef ExceptionPtrs As EXCEPTION_POINTERS) As Long
  Dim Rec As EXCEPTION_RECORD
  Dim strException As String
  Rec = ExceptionPtrs.pExceptionRecord
  Do Until Rec.pExceptionRecord = 0
    CopyExceptionRecord Rec, Rec.pExceptionRecord, Len(Rec)
  Loop
  strException = GetExceptionText(Rec.ExceptionCode)
  m_Description = strException
  SendSvrMsg "Server error: " & Rec.ExceptionCode & " -- " & strException
  SendSvrMsg "Trying to continue execution"
  ExceptionFilter = EXCEPTION_CONTINUE_EXECUTION
End Function

Public Sub Error_Connect()
    Call SetUnhandledExceptionFilter(AddressOf ExceptionFilter)
End Sub

Public Sub Error_Disconnect()
    Call SetUnhandledExceptionFilter(0)
End Sub
