**free
      *********************************************************************
      *                                                                   *
      *                  IBM Web Services Client for ILE                  *
      *                                                                   *
      *  FILE NAME:      redaxis.RPGLE                                    *
      *                                                                   *
      *  DESCRIPTION:    Source to do REST request using transport APIs   *
      *                  The intended target/server is a local Node-RED   *
      *                  instance running in the PASE environment         *
      *      Based on https://www.ibm.com/developerworks/community/wikis/
      //                form/anonymous/api/
      //                wiki/cedbf05d-28cf-4686-bb3d-064b3d9d343f/
      //                page/20a19c3e-fb0b-49d6-a6e3-2adde04679d2/
      //                attachment/2de6ce30-bf0e-461e-a5f5-28c0b9e51602/
      //                media/restRS.rpgle
      *                                                                   *
      *********************************************************************
      * LICENSE AND DISCLAIMER                                            *
      * ----------------------                                            *
      * This material contains IBM copyrighted sample programming source  *
      * code ( Sample Code ).                                             *
      * IBM grants you a nonexclusive license to compile, link, execute,  *
      * display, reproduce, distribute and prepare derivative works of    *
      * this Sample Code.  The Sample Code has not been thoroughly        *
      * tested under all conditions.  IBM, therefore, does not guarantee  *
      * or imply its reliability, serviceability, or function. IBM        *
      * provides no program services for the Sample Code.                 *
      *                                                                   *
      * All Sample Code contained herein is provided to you "AS IS"       *
      * without any warranties of any kind. THE IMPLIED WARRANTIES OF     *
      * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND             *
      * NON-INFRINGMENT ARE EXPRESSLY DISCLAIMED.                         *
      * SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF IMPLIED          *
      * WARRANTIES, SO THE ABOVE EXCLUSIONS MAY NOT APPLY TO YOU.  IN NO  *
      * EVENT WILL IBM BE LIABLE TO ANY PARTY FOR ANY DIRECT, INDIRECT,   *
      * SPECIAL OR OTHER CONSEQUENTIAL DAMAGES FOR ANY USE OF THE SAMPLE  *
      * CODE INCLUDING, WITHOUT LIMITATION, ANY LOST PROFITS, BUSINESS    *
      * INTERRUPTION, LOSS OF PROGRAMS OR OTHER DATA ON YOUR INFORMATION  *
      * HANDLING SYSTEM OR OTHERWISE, EVEN IF WE ARE EXPRESSLY ADVISED OF *
      * THE POSSIBILITY OF SUCH DAMAGES.                                  *
      *                                                                   *
      *  <START_COPYRIGHT>                                                *
      *                                                                   *
      *  Licensed Materials - Property of IBM                             *
      *                                                                   *
      *  5770-SS1                                                         *
      *                                                                   *
      *  (c) Copyright IBM Corp. 2016, 2019                               *
      *  All Rights Reserved                                              *
      *                                                                   *
      *  U.S. Government Users Restricted Rights - use,                   *
      *  duplication or disclosure restricted by GSA                      *
      *  ADP Schedule Contract with IBM Corp.                             *
      *                                                                   *
      *  Status: Version 1 Release 0                                      *
      *  <END_COPYRIGHT>                                                  *
      *                                                                   *
      *********************************************************************

      *
      * CRTrpgMOD MODULE(AMRA/RESTrs) SRCSTMF('/restrs.rpgle') DBGVIEW(*ALL) 
      * 
      * CRTPGM PGM(AMRA/RESTRS) MODULE(AMRA/RESTRS) BNDSRVPGM((QSYSDIR/QAXIS10CC)) 
      *

      /COPY /qibm/proddata/os/webservices/V1/client/include/Axis.rpgleinc
                                                  
       DCL-S rc              INT(10);
       DCL-S tHandle         POINTER;

       DCL-S uri             CHAR(200);
       DCL-S response        CHAR(32768);
       DCL-S request         CHAR(32768);
       DCL-S propBuf1        CHAR(100);
       DCL-S propBuf2        CHAR(100);
       DCL-S propInt         INT(10);
       DCL-S NULLSTR         CHAR(1) inz(X'00');
       DCL-S NONE            CHAR(5);       

      *--------------------------------------------------------------------
      * Web service logic. The code will attempt to invoke a Web service. 
      *-------------------------------------------------------------------  

       // Uncomment if need to debug.
       // axiscAxisStartTrace('/tmp/axistransport.log': *null);
              
       // Set URI to web service
       uri = 'https://localhost:1880/rpg-test';
       
       // Create HTTP transport handle.
       tHandle = axiscTransportCreate(uri:AXISC_PROTOCOL_HTTP11);
       if (tHandle = *NULL);
         PRINT ('TransportCreate() failed');
         return;
       endif;

       // Set HTTP method - redundant since default is GET
       propBuf1 = 'GET' + X'00';
       rc = axiscTransportSetProperty(tHandle: AXISC_PROPERTY_HTTP_METHOD: 
                                      %addr(propBuf1));
       
       // Flush transport so request is sent and receive response.
       rc = axiscTransportFlush(tHandle);
       if (rc = -1);
           checkError ('TransportFlush()');
       else;
         receiveData();
       endif;

       // Cleanup handle.
       axiscTransportDestroy(tHandle);
                                                      
       *INLR=*ON;
                                                 
      /end-free   
      
       // =========================================
       // Print to standard out
       // =========================================
       DCL-PROC PRINT ;
         dcl-pi *n;
           msg varchar(5000) const;
         end-pi;
         
         dcl-pr printf extproc(*dclcase);
            template pointer value options(*string);
            dummy int(10) value options(*nopass);
         end-pr;
         
         dcl-c NEWLINE CONST(x'15');

         printf(%TRIM(msg) + NEWLINE);
       END-PROC PRINT;         
       
       // =========================================
       // Handle error
       // =========================================
       DCL-PROC checkError ;
         dcl-pi *n;
           msg varchar(5000) const;
         end-pi;       
         
         DCL-S axisCode   INT(10);
         DCL-S statusCode POINTER;
         DCL-S rc         INT(10);

         axisCode = axiscTransportGetLastErrorCode(tHandle);
         PRINT (msg + ' call failed: ' +
                %CHAR(axisCode) + ':' + 
                %STR(axiscTransportGetLastError(tHandle)));

       END-PROC checkError;
          
       // =========================================
       // Receive data
       // =========================================
       DCL-PROC receiveData ;
         dcl-pi *n;
         end-pi;       
         
         DCL-S header     POINTER;
         DCL-S property   CHAR(100);
         DCL-S bytesRead  INT(10) inz(0);
                  
         clear response;
         clear header;
         
         rc = axiscTransportReceive(tHandle: 
                                    %ADDR(response): 
                                    %SIZE(response): 0);
         if (rc = 0);
           PRINT ('No data to read');
         else;
           dow rc > 0 AND bytesRead < %SIZE(response);
             bytesRead = bytesRead + rc;
             rc = axiscTransportReceive(tHandle: 
                                        %ADDR(response)+bytesRead: 
                                        %SIZE(response)-bytesRead: 
                                        0);
           enddo;
         endif;

         if (rc = -1);
           checkError ('TransportReceive()');
         elseif (bytesRead  > 0);
           PRINT ('Bytes read: ' + %CHAR(bytesRead));
           PRINT ('Data: ' + response);
         endif;

         // Dump status code
         rc = axiscTransportGetProperty(tHandle: 
                                        AXISC_PROPERTY_HTTP_STATUS_CODE: 
                                        %addr(header));
         if (rc = -1);
           checkError ('TransportGetProperty()');
         endif;

         PRINT ('HTTP status code: ' + %str(header));

       END-PROC receiveData;                                                           
