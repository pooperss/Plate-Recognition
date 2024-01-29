import 'package:flutter/material.dart';

const primaryColor = Color(0xFF0D47A1); // A deep blue color
const primaryVariantColor = Colors.white; // A lighter blue color
const secondaryColor = Color(0xFFFFC107); // A bright amber color
var spreadsheetId = '';
var credentials = '';
const secretUsername = 's';
const secretPassword = 's';

/* var spreadsheetId = '17RuoM-1lQS6YHBJc86Rslc7tjcrxCeJ1Z0khmgc717c';
 var credentials = r'''
 {
   "type": "service_account",
   "project_id": "plates-401503",
   "private_key_id": "2012ef3d6e6b54d7d0bcde4d40b0e0830937d5c4",
   "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCeEC4QHab6/bRQ\nHlF+dDuFTuJxj82G94oULs64EtHk32z7A7KnNMSdRn63IgcHsnj9/zoSERzGjaUn\ndARrdgHffUx5YrR7Nm4yLFh0w4m7QnQwihLXvup/627TFubA9BiBnya+mPU8mTCG\nSRe/8K/2y1xwlCQVhRHGAzYS/Ml/ppmBngCE/YIPMemDRMOYAf2J8LA25qnC2e+n\nfCGGDptqWCQ6QdcwKh7DQw9FVJlXNN4u+AfmwSubzeofWcqVFagI63B58jDb5IcI\nC4nsjmP/+GAT9zrQZlR+k6uv5dbZU9zLnv8Ee+rWrdbdn1Yh5jy3D+gFlH8Jn/3i\ngjCvZpr/AgMBAAECggEATENJPkxYRyyGxctDDay+FR1RA3LbOt4PmJpW8hhefjvQ\nxLHtjmBW5v1e4TRBSRTy7LYqyhHInQI1p7oB8elfkPnPHpghtXs3Iu0jhr7boua2\n0b6kxcSfNzYcZCveDUYY1t23n2mElYbiE0CL/Xd/JyfKg6TuXhW01CGzgujFvdkc\n+kk4FQrxk8hdPx0BAiWviM7f8UuMIXhJ9VEvkalUOF5QrWzhaMVwQdlDwaMaTjBi\nQ41/qc0fGskE97F7d7uRO/JL3615tSok5kvgJ1DlZfcN75IsTevCF82nZ1YDizoD\nDbuwsar36wum8URMM+kNtfArCLcsU3ojWn6WQmvEKQKBgQDYzWTG232afptufC0m\nik4zsurUlmnAs4T4Zc8KzTNboPN/k8c0qDCljg3Eqrdppp6vuBDtUpQE76stSL8W\n9af/wHI1bg/XDcU1RD3Xl+qsg8msZGBgINiECzLjIXxbTLN5N4ZCxnPB2VjcqPaW\nTVeIxCrw+NJQqq+Gg2mbk4e69wKBgQC6pBIFeBLAzJurfZmDVuBlYGWTNvwci92M\n253aXQ57UKk6aZeuQMFOoOrX+zytn/4JnKb/cldAR+XfsrDXy0SaTRmlglvBaKHF\nGu46Dwml2mRfBVRIH3PXljq596UKurudFR7t6qM34+K24UGS8LWRHaNmUohHMjFk\nxhsrztlWOQKBgFaxGuEhl4IVqlVttig5Gbg2jQxg8PyrTDp/i2DIWQcEvxl+oCOA\nNaOdwAeqNBk9FSsysSIU6TdoFszO0AqARKNR8tlGn3LhAMCh/xCcoKxHLneO07Lc\nr3dtevWzyCRB8WpBN6Cv9k3HeW8S6TeEycHYn0soVAEJn5JsLeiV/6pVAoGAZW6/\ngItmHbPVMlkbMf7oCxBdg6lRUK5OpLvCSSdjtG782YsDbScyJ2pa1zBqJK4b4Ntr\nAs8ATiYE7xLs+wo0aWtXcdSryyvzJuzg5VrA0osjG2UJDf1R9qtllSXaYz9isRcG\nbSSkub42u08mVRZOhuRFpllaSN8lavAjWiabhTkCgYB/eJiMAZZFFAkJDUwCZrqd\nqyaO4ygUoCI3GtQg78hN2qeGhDmMTpnHbwAjz64I0hRQDPJ0SA3lENkfUVKo/UoT\nvHf5oSu+vovSJO/RcJQrlvvkgQ+TLbwn00yp8NUrI5nn9bOSqGHv+rUmjvm99FvX\no7x5PXDegpIAqcGBzLbPVw==\n-----END PRIVATE KEY-----\n",
   "client_email": "plates@plates-401503.iam.gserviceaccount.com",
   "client_id": "105060596894743702124",
   "auth_uri": "https://accounts.google.com/o/oauth2/auth",
   "token_uri": "https://oauth2.googleapis.com/token",
   "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
   "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/plates%40plates-401503.iam.gserviceaccount.com",
   "universe_domain": "googleapis.com"
 }
 ''';
*/
