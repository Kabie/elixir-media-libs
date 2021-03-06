defmodule Rtmp.Handshake.DigestHandshakeFormatTest do
  use ExUnit.Case, async: true

  alias Rtmp.Handshake.DigestHandshakeFormat, as: DigestHandshakeFormat

  @jwplayer_c0 <<0x03>>
  @jwplayer_c1 <<0x00, 0x12, 0x6c, 0xbb, 0x80, 0x00, 0x07, 0x02, 0x62, 0x3f, 0x16, 0x27, 0xc6, 0x1d, 0xac,
                  0x34, 0x38, 0x46, 0xf2, 0xbc, 0x67, 0xce, 0xed, 0xac, 0xe3, 0x00, 0x0d, 0x73, 0x54, 0x46, 0x03,
                  0x95, 0xba, 0xc3, 0x3b, 0xd7, 0xf5, 0xa4, 0x40, 0x5f, 0xa9, 0xd4, 0x7b, 0x0d, 0x91, 0xd9, 0x98,
                  0xbd, 0xaf, 0x21, 0xd0, 0x3d, 0xd4, 0xf0, 0x2f, 0x91, 0x47, 0xd3, 0xd4, 0x70, 0x5b, 0xd4, 0xd0,
                  0x67, 0x84, 0x64, 0x2b, 0x0d, 0x29, 0x66, 0xbd, 0x02, 0x09, 0x86, 0x8b, 0x64, 0x0d, 0x45, 0x01,
                  0xb0, 0xf8, 0xa7, 0xca, 0x0e, 0xa2, 0x47, 0x6d, 0x2a, 0xec, 0x94, 0xc0, 0xc8, 0x75, 0x1f, 0x44,
                  0x64, 0xb5, 0xa9, 0x18, 0x3c, 0x81, 0xcb, 0x86, 0xc0, 0x6d, 0xe6, 0x93, 0x9d, 0x86, 0x5c, 0x96,
                  0x43, 0xc7, 0xac, 0x53, 0xf7, 0xb8, 0xf8, 0xbb, 0x5d, 0x73, 0xa7, 0x5a, 0x3a, 0x78, 0xf2, 0xaa,
                  0x88, 0x21, 0x2d, 0x78, 0x0f, 0x86, 0xc0, 0xcb, 0x61, 0x0d, 0x03, 0xcf, 0x54, 0x81, 0xc7, 0xab,
                  0xd3, 0x76, 0xb6, 0x13, 0x38, 0x03, 0xcf, 0x53, 0x96, 0x41, 0xa3, 0xc9, 0xbc, 0x8b, 0x48, 0x2a,
                  0x58, 0xc9, 0xd3, 0xf3, 0x65, 0x96, 0x96, 0x0f, 0x1c, 0x8a, 0x88, 0xb3, 0x7c, 0xbb, 0x53, 0x40,
                  0x53, 0x47, 0xa2, 0xf8, 0xbe, 0x57, 0xe1, 0x8a, 0x3b, 0xc1, 0xf6, 0xdc, 0x97, 0x32, 0xfb, 0xeb,
                  0x4b, 0x06, 0x8e, 0x70, 0x68, 0x71, 0x84, 0x71, 0xdc, 0x6e, 0xae, 0x54, 0xa5, 0xa7, 0xb7, 0x18,
                  0xf8, 0xdf, 0x89, 0xab, 0x1f, 0x04, 0x64, 0xa3, 0xc1, 0x40, 0x82, 0xab, 0x8d, 0x7f, 0x41, 0xac,
                  0xdd, 0xc5, 0x2c, 0xe1, 0xe5, 0x45, 0x6f, 0x00, 0x72, 0xdf, 0x49, 0xe8, 0x7a, 0x09, 0x34, 0xa3,
                  0xce, 0xb9, 0x06, 0xd4, 0x09, 0x45, 0x48, 0x07, 0x9b, 0x82, 0x9a, 0xab, 0xff, 0xf8, 0x86, 0x97,
                  0xc3, 0x90, 0xd1, 0x1d, 0x24, 0xe9, 0x81, 0x3b, 0x22, 0x5f, 0xb1, 0x01, 0x47, 0xb7, 0xb0, 0xa4,
                  0xc7, 0x79, 0x4c, 0xf7, 0xae, 0x09, 0xdc, 0x34, 0xe9, 0x25, 0x2c, 0x7c, 0x46, 0x7b, 0x1b, 0x02,
                  0x7c, 0x07, 0x2a, 0xa2, 0x6c, 0xce, 0xcc, 0x01, 0xfe, 0xa2, 0x02, 0xbb, 0xc1, 0x5d, 0x41, 0x21,
                  0xea, 0xd7, 0x95, 0x9e, 0x26, 0xfe, 0x8d, 0xdb, 0xe8, 0x33, 0x9a, 0xf9, 0x0e, 0x1b, 0x00, 0xa7,
                  0x28, 0x84, 0x52, 0xd8, 0x30, 0xb5, 0x05, 0xba, 0x87, 0xa9, 0x23, 0xe3, 0x46, 0xa5, 0x78, 0x10,
                  0x7a, 0xe5, 0xa9, 0xcc, 0xf1, 0xa5, 0xae, 0x95, 0xe8, 0xd0, 0xe4, 0xc3, 0x43, 0xc4, 0x45, 0x9c,
                  0x4e, 0xcd, 0xa3, 0x8c, 0x52, 0xc8, 0x94, 0x6c, 0x86, 0xab, 0x77, 0xa4, 0xde, 0x39, 0x0f, 0x7b,
                  0x98, 0x0b, 0xd3, 0x94, 0xe4, 0x21, 0x40, 0xb5, 0x0d, 0xc1, 0x01, 0x94, 0x83, 0xa4, 0xc8, 0xf2,
                  0x27, 0xda, 0x7f, 0x3f, 0x8a, 0xce, 0xfa, 0x1d, 0x2c, 0xa2, 0x39, 0xa0, 0x8a, 0x73, 0x87, 0x87,
                  0x9f, 0x9f, 0xc8, 0xa2, 0xa4, 0x0a, 0x07, 0x88, 0x0d, 0x98, 0x8e, 0xd5, 0xcb, 0x1b, 0x2b, 0x00,
                  0x7a, 0xbb, 0xaf, 0xce, 0x8a, 0x54, 0x52, 0x35, 0x37, 0x64, 0xc3, 0x6c, 0xbc, 0x07, 0xe5, 0x70,
                  0x13, 0x1b, 0x24, 0xa6, 0x9c, 0x48, 0xc4, 0xa4, 0x3f, 0x38, 0xd6, 0x22, 0x98, 0x89, 0x9c, 0x38,
                  0x03, 0xdc, 0x1e, 0x44, 0xcf, 0xe9, 0x6c, 0x5e, 0x48, 0x9a, 0x33, 0xc4, 0x9f, 0xb9, 0xc0, 0xbe,
                  0x79, 0x6d, 0x4c, 0x9e, 0x82, 0xab, 0x61, 0x6a, 0xd3, 0x95, 0x1d, 0x56, 0xd2, 0x12, 0xbc, 0x3b,
                  0x15, 0x9c, 0x1e, 0x95, 0x0a, 0x36, 0x2c, 0x1e, 0xfd, 0xcb, 0x73, 0x46, 0x4e, 0x4c, 0xe5, 0x53,
                  0x63, 0xae, 0xf1, 0x96, 0xe4, 0x76, 0x75, 0x28, 0x36, 0x94, 0xc9, 0xb6, 0x35, 0xb7, 0x5a, 0x32,
                  0xfa, 0xd1, 0x7c, 0xe5, 0x80, 0x0b, 0x33, 0x0c, 0xaa, 0x35, 0xbf, 0x96, 0xc0, 0xe5, 0x02, 0x55,
                  0x80, 0x97, 0x68, 0x6d, 0xf5, 0x52, 0xb3, 0x4b, 0x77, 0x0c, 0x1b, 0x8a, 0x55, 0xcd, 0xa0, 0x88,
                  0x84, 0xce, 0x02, 0x6c, 0x99, 0x76, 0x91, 0x7a, 0x61, 0x79, 0x3a, 0xc1, 0x66, 0xcd, 0xe9, 0x36,
                  0x73, 0x2d, 0x41, 0xd2, 0x2b, 0x05, 0xc4, 0x88, 0x11, 0x74, 0x24, 0x83, 0x50, 0xed, 0x37, 0x5e,
                  0xc5, 0xc3, 0xfa, 0x84, 0x4d, 0x81, 0xf3, 0x2d, 0xf7, 0xf0, 0xfd, 0x08, 0xbc, 0x10, 0x9e, 0xe2,
                  0xef, 0xdb, 0x4f, 0xcb, 0x6e, 0x9e, 0x14, 0x28, 0x39, 0x3a, 0x9a, 0xfa, 0x49, 0xf8, 0x63, 0x63,
                  0x8e, 0xa7, 0xe1, 0xb6, 0xdf, 0x37, 0xbd, 0xd7, 0xa6, 0xfd, 0xcf, 0x40, 0x40, 0x3d, 0x00, 0xb8,
                  0x5b, 0x44, 0x40, 0x82, 0x3e, 0x49, 0x9d, 0xcb, 0xf5, 0xaa, 0x30, 0x08, 0x04, 0x95, 0x39, 0x87,
                  0xb9, 0x1f, 0xb3, 0xb7, 0xfc, 0xe4, 0x72, 0x1e, 0xbc, 0x82, 0x7b, 0x16, 0x7f, 0x2c, 0xea, 0x06,
                  0x9e, 0x5c, 0xb1, 0xb7, 0x34, 0x46, 0x62, 0x11, 0xf6, 0x1e, 0x4a, 0xcd, 0xeb, 0xa8, 0xed, 0x1a,
                  0xb6, 0x51, 0xc3, 0x68, 0xfb, 0x31, 0x2d, 0x9d, 0x84, 0x21, 0x9e, 0x96, 0xbf, 0xe5, 0x1b, 0x6b,
                  0x7b, 0x83, 0x47, 0xdd, 0x45, 0xff, 0xc2, 0x70, 0x5d, 0xc3, 0xa5, 0x1d, 0x6b, 0x79, 0x27, 0xd1,
                  0x6d, 0x45, 0x47, 0x7b, 0x25, 0xaf, 0xed, 0x58, 0x1d, 0x8f, 0x2d, 0xcd, 0xeb, 0x25, 0x5e, 0x62,
                  0x68, 0x5f, 0x33, 0xf3, 0x50, 0x81, 0x0f, 0x5f, 0x95, 0x85, 0xf9, 0x99, 0x05, 0x1d, 0xff, 0x6c,
                  0x9a, 0x9e, 0x3d, 0x3d, 0xd1, 0x1f, 0x53, 0x3a, 0x2e, 0x26, 0x2e, 0x6b, 0xda, 0xb5, 0x41, 0x6d,
                  0x36, 0x45, 0x57, 0x1f, 0x0f, 0xea, 0x24, 0x3e, 0xce, 0x54, 0x79, 0x25, 0x8a, 0x9c, 0x27, 0xe8,
                  0x72, 0x27, 0x74, 0x4e, 0x05, 0x71, 0x01, 0x9f, 0x68, 0xdf, 0x44, 0xc7, 0x25, 0xc8, 0xbc, 0x95,
                  0x7f, 0x33, 0xea, 0x08, 0xa9, 0xc4, 0x40, 0x15, 0x93, 0xac, 0x69, 0x04, 0x8e, 0xd9, 0xb1, 0x98,
                  0x18, 0xff, 0x16, 0x33, 0x61, 0x18, 0xb3, 0x08, 0xd0, 0x84, 0x8c, 0x49, 0xdc, 0x22, 0x2b, 0x9c,
                  0x09, 0xc5, 0x56, 0x97, 0xed, 0x80, 0xeb, 0x03, 0xba, 0x66, 0x33, 0xdc, 0xf9, 0x7a, 0xea, 0xff,
                  0xc6, 0x27, 0xef, 0xd6, 0x02, 0x4e, 0x1b, 0xa7, 0x2d, 0xfb, 0x58, 0xd7, 0xe8, 0x55, 0x48, 0x4b,
                  0x85, 0xb2, 0x0c, 0xea, 0xac, 0x66, 0x59, 0x12, 0x0e, 0xcc, 0x08, 0xb9, 0x1e, 0x08, 0xdb, 0x7b,
                  0x01, 0x60, 0x70, 0xb7, 0xd2, 0x49, 0x62, 0x5b, 0x4e, 0x45, 0x9e, 0xf4, 0xf4, 0x9c, 0x73, 0xbd,
                  0x20, 0xaf, 0xaf, 0xc2, 0xb9, 0xcb, 0x37, 0x10, 0x92, 0xed, 0x8a, 0x62, 0x11, 0x64, 0x66, 0xf4,
                  0xe2, 0x59, 0x7e, 0xaa, 0x24, 0x76, 0x64, 0x18, 0xab, 0x34, 0x6d, 0x18, 0xc8, 0xc9, 0x1f, 0xba,
                  0x62, 0x03, 0x01, 0xa9, 0xfb, 0xe3, 0xe5, 0x15, 0x06, 0x9d, 0xb0, 0x8f, 0x49, 0xa3, 0x4f, 0x91,
                  0x44, 0x3a, 0xd5, 0x25, 0xd0, 0x55, 0x52, 0x0f, 0x6b, 0x19, 0x30, 0xfb, 0x9b, 0x2a, 0x47, 0xef,
                  0xbb, 0xdd, 0x36, 0x36, 0xad, 0x66, 0x91, 0x6f, 0x88, 0xe9, 0xd2, 0xb4, 0x2d, 0xcd, 0x99, 0xd2,
                  0xb7, 0x0a, 0xec, 0xa1, 0x6c, 0xba, 0xdb, 0xf8, 0x6a, 0xd7, 0xed, 0x82, 0xd3, 0x72, 0x94, 0x4c,
                  0x57, 0x5f, 0x9a, 0xaa, 0xb4, 0x04, 0x92, 0x52, 0x36, 0xca, 0x11, 0xef, 0x81, 0x7a, 0x83, 0xa8,
                  0x87, 0x24, 0x6d, 0xe2, 0x10, 0x43, 0xd4, 0xe2, 0x9e, 0x25, 0x37, 0x83, 0xdc, 0x72, 0x7f, 0x63,
                  0x19, 0xf8, 0x2a, 0x84, 0x94, 0x6c, 0xf2, 0xf6, 0xaf, 0x4a, 0x53, 0x28, 0xd8, 0xb8, 0x5e, 0xd0,
                  0x1e, 0x45, 0x65, 0x43, 0xbd, 0x72, 0x4b, 0x55, 0x0a, 0x00, 0xac, 0x39, 0x42, 0xdc, 0xef, 0x9b,
                  0x25, 0x4e, 0x36, 0x61, 0x2f, 0x0d, 0xdb, 0x80, 0x0f, 0x8f, 0xe6, 0x1e, 0x0e, 0xd2, 0x7e, 0x12,
                  0x28, 0x56, 0xf5, 0x33, 0x8c, 0xa8, 0x6e, 0xfe, 0x63, 0x7f, 0xfb, 0x2e, 0xf7, 0xde, 0x0e, 0x7c,
                  0xd9, 0x4c, 0xa4, 0x8d, 0xb7, 0x69, 0xef, 0xac, 0x6e, 0x74, 0x0c, 0x85, 0x75, 0xdc, 0x57, 0x80,
                  0xa0, 0x2e, 0xca, 0xf4, 0x8a, 0x17, 0x0e, 0x21, 0x0e, 0x7c, 0x33, 0xa3, 0x8d, 0xfe, 0xb3, 0xdf,
                  0x5f, 0x7d, 0x8b, 0xe5, 0x84, 0x26, 0x1a, 0x3d, 0x1a, 0x76, 0x8a, 0x06, 0x0d, 0xb0, 0xb1, 0x95,
                  0xe9, 0x14, 0x61, 0x3a, 0xfb, 0xf6, 0xce, 0x8b, 0x5d, 0x6f, 0x5a, 0x91, 0xc3, 0x32, 0x65, 0xb3,
                  0x1c, 0xfa, 0xfb, 0xbe, 0xd7, 0x2f, 0xe9, 0xd0, 0xa8, 0x24, 0x0a, 0x66, 0xc7, 0x60, 0xdf, 0xdc,
                  0x83, 0x21, 0xb2, 0x28, 0x2b, 0x94, 0xee, 0x94, 0x6d, 0xa6, 0x21, 0x4e, 0x07, 0xd1, 0xe8, 0x6b,
                  0x1d, 0xe9, 0xd3, 0x00, 0xca, 0xca, 0x4c, 0xd2, 0x98, 0x7b, 0xd0, 0x37, 0xde, 0x78, 0xfd, 0x84,
                  0x0e, 0xf1, 0x54, 0x6d, 0x2c, 0x26, 0x82, 0x53, 0x37, 0x01, 0x01, 0x23, 0x67, 0x4a, 0x78, 0xa6,
                  0x12, 0x49, 0x15, 0xb9, 0x25, 0x87, 0x06, 0x8e, 0xe7, 0xaf, 0x24, 0x41, 0x5e, 0x9e, 0x8d, 0x27,
                  0x93, 0xa6, 0x80, 0xae, 0x72, 0xa0, 0x7c, 0x7b, 0x46, 0xd2, 0x1e, 0xcc, 0x4e, 0xb7, 0xb5, 0x17,
                  0x28, 0x73, 0x82, 0x33, 0x20, 0x8e, 0xfe, 0xe2, 0x39, 0x38, 0xe4, 0xe7, 0xf2, 0xa0, 0xa3, 0xb9,
                  0x76, 0x07, 0xc5, 0x36, 0x51, 0xe0, 0x57, 0x1a, 0x49, 0xf4, 0x61, 0xc6, 0x1f, 0x48, 0xf4, 0x70,
                  0x29, 0xa1, 0x2e, 0xfb, 0xba, 0xfd, 0x3f, 0xb0, 0xd0, 0x76, 0xdb, 0x18, 0x7c, 0x63, 0xed, 0xa1,
                  0xe4, 0xb5, 0x50, 0xb5, 0x43, 0xa8, 0x5d, 0x49, 0xf2, 0xa4, 0x07, 0x96, 0xf6, 0x40, 0xfc, 0xef,
                  0x9c, 0xc8, 0x2c, 0xe1, 0xd0, 0x70, 0xcd, 0x87, 0x94, 0x24, 0xea, 0xfa, 0xf5, 0x56, 0x39, 0xeb,
                  0x22, 0xfa, 0x64, 0x54, 0x4b, 0x9d, 0x40, 0xb0, 0x83, 0x5b, 0xfa, 0xb5, 0x44, 0x8e, 0x6b, 0x48,
                  0x7e, 0xfa, 0x49, 0xee, 0x9a, 0x82, 0x73, 0x7f, 0x25, 0xb1, 0x0e, 0x06, 0x43, 0xf4, 0xaa, 0xd4,
                  0x92, 0x72, 0x7f, 0xf2, 0xb5, 0x8f, 0x4b, 0xac, 0x9b, 0x24, 0xaf, 0x28, 0xee, 0x48, 0xd4, 0x39,
                  0x68, 0x8f, 0x59, 0x61, 0x2c, 0xaf, 0x93, 0x0b, 0xb2, 0x86, 0xa2, 0x3e, 0x21, 0xdb, 0x78, 0x7e,
                  0x9e, 0xdb, 0xcc, 0x46, 0xb9, 0x97, 0x49, 0x0c, 0x2c, 0x32, 0xab, 0x3d, 0x39, 0xab, 0x44, 0x7b,
                  0x7c, 0xaf, 0xf3, 0x32, 0x0d, 0xcc, 0x5b, 0xad, 0x42, 0x57, 0xf2, 0x0d, 0x2f, 0x1b, 0xe3, 0xbf,
                  0xf2, 0xe3, 0xe7, 0xb4, 0x9a, 0x29, 0x37, 0x78, 0x4a, 0x11, 0xcd, 0x9f, 0xcc, 0x6e, 0xbb, 0xdc,
                  0x45, 0xb0, 0xdd, 0x0b, 0x83, 0xc0, 0xc0, 0x0d, 0x51, 0xbc, 0xbb, 0x75, 0x12, 0x6a, 0x85, 0xba,
                  0x71, 0x80, 0x5d, 0x9b, 0x6c, 0xa4, 0x93, 0xf4, 0xae, 0xba, 0x28, 0x82, 0xd0, 0x56, 0x79, 0xdc,
                  0x39, 0x6d, 0xbc, 0x49, 0x62, 0x7d, 0x51, 0x60, 0xaa, 0x8d, 0x01, 0xd9, 0x15, 0xd0, 0x9c, 0xf9,
                  0x36, 0x5f, 0x82, 0x1f, 0x2a, 0xfc, 0xd6, 0xc1, 0x18, 0x87, 0xd8, 0x89, 0x49, 0x75, 0x29, 0xfe,
                  0xbc, 0x35, 0x37, 0x54, 0xec, 0x0e, 0x41, 0x9a, 0xec, 0x45, 0x37, 0xf7, 0x46, 0xbd, 0x17, 0x06,
                  0xb3, 0xf1, 0xc7, 0x70, 0x9a, 0x2b, 0x5a, 0x13, 0x3a, 0x58, 0xfc, 0xb3, 0x2b, 0xd0, 0x16, 0x07,
                  0x47, 0xc1, 0xd1, 0x4b, 0x7d, 0x77, 0x17, 0xd9, 0x34, 0x5a, 0x09, 0xd2, 0x8c, 0xfc, 0x6e, 0x39,
                  0x59>>

  test "Can validate JWPlayer handshake" do
    c0_and_c1 = @jwplayer_c0 <> @jwplayer_c1

    assert DigestHandshakeFormat.is_valid_format(c0_and_c1) == :yes
  end

  test "No unparsed binary after reading c0, c1, and c2" do
    c0_and_c1 = @jwplayer_c0 <> @jwplayer_c1

    state = DigestHandshakeFormat.new()
    {state, _} = DigestHandshakeFormat.process_bytes(state, c0_and_c1)
    {state, _} = DigestHandshakeFormat.process_bytes(state, @jwplayer_c1)

    assert state.unparsed_binary == <<>>
  end

  test "Can recognize its own c0 and c1 as valid" do
    {_, binary} = DigestHandshakeFormat.new() |> DigestHandshakeFormat.create_p0_and_p1_to_send()

    assert :yes == DigestHandshakeFormat.is_valid_format(binary)
  end
end