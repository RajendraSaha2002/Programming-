#define _WIN32_WINNT 0x0600
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>

// Link with the Winsock library
#pragma comment(lib, "Ws2_32.lib")

// Helper function to convert a two-character hex string to a byte
// Example: "0F" -> 15, "A1" -> 161
unsigned char hexToByte(const char* hex) {
    unsigned char value = 0;
    // Read the first character
    if (hex[0] >= '0' && hex[0] <= '9') {
        value = (hex[0] - '0') << 4;
    } else if (hex[0] >= 'A' && hex[0] <= 'F') {
        value = (hex[0] - 'A' + 10) << 4;
    } else if (hex[0] >= 'a' && hex[0] <= 'f') {
        value = (hex[0] - 'a' + 10) << 4;
    }

    // Read the second character
    if (hex[1] >= '0' && hex[1] <= '9') {
        value |= (hex[1] - '0');
    } else if (hex[1] >= 'A' && hex[1] <= 'F') {
        value |= (hex[1] - 'A' + 10);
    } else if (hex[1] >= 'a' && hex[1] <= 'f') {
        value |= (hex[1] - 'a' + 10);
    }

    return value;
}

// Function to send the Wake-on-LAN magic packet
bool sendMagicPacket(const std::string& macAddress, const std::string& broadcastAddress) {
    WSADATA wsaData;
    SOCKET sock;
    SOCKADDR_IN sin;
    char magicPacket[102]; // 6 bytes of FF + 16 * 6 bytes of MAC address

    // Initialize Winsock
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        std::cerr << "WSAStartup failed." << std::endl;
        return false;
    }

    // Create a UDP socket
    sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock == INVALID_SOCKET) {
        std::cerr << "socket creation failed." << std::endl;
        WSACleanup();
        return false;
    }

    // Enable broadcast mode for the socket
    char broadcast = '1';
    if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast)) < 0) {
        std::cerr << "setsockopt (SO_BROADCAST) failed." << std::endl;
        closesocket(sock);
        WSACleanup();
        return false;
    }

    // Set up the destination address for the magic packet
    sin.sin_family = AF_INET;
    sin.sin_port = htons(9); // WoL typically uses port 9
    sin.sin_addr.s_addr = inet_addr(broadcastAddress.c_str());
    if (sin.sin_addr.s_addr == INADDR_NONE) {
        std::cerr << "Invalid broadcast address." << std::endl;
        closesocket(sock);
        WSACleanup();
        return false;
    }

    // Construct the magic packet
    // The packet starts with 6 bytes of all FF's
    // Construct the magic packet
    // The packet starts with 6 bytes of all FF's
    for (int i = 0; i < 6; ++i) {
        magicPacket[i] = 0xFF;
    }

    // Followed by 16 repetitions of the target's MAC address
    // Parse the MAC address string (e.g., "AA-BB-CC-DD-EE-FF")
    std::string cleanMac = macAddress;
    cleanMac.erase(std::remove(cleanMac.begin(), cleanMac.end(), ':'), cleanMac.end());
    cleanMac.erase(std::remove(cleanMac.begin(), cleanMac.end(), '-'), cleanMac.end());

    // Ensure the MAC address is 12 characters long (6 bytes)
    if (cleanMac.length() != 12) {
        std::cerr << "Invalid MAC address format. Please use 'AA-BB-CC-DD-EE-FF'." << std::endl;
        closesocket(sock);
        WSACleanup();
        return false;
    }

    // Append the MAC address 16 times
    for (int i = 0; i < 16; ++i) {
        for (int j = 0; j < 6; ++j) {
            magicPacket[6 + (i * 6) + j] = hexToByte(cleanMac.substr(j * 2, 2).c_str());
        }
    }

    // Send the magic packet
    int bytesSent = sendto(sock, magicPacket, sizeof(magicPacket), 0, (SOCKADDR*)&sin, sizeof(sin));
    if (bytesSent == SOCKET_ERROR) {
        std::cerr << "sendto failed with error: " << WSAGetLastError() << std::endl;
        closesocket(sock);
        WSACleanup();
        return false;
    }

    std::cout << "Magic packet sent successfully! " << bytesSent << " bytes sent." << std::endl;

    // Clean up
    closesocket(sock);
    WSACleanup();
    return true;
}

int main() {
    std::string mac;
    std::string broadcast;

    std::cout << "--- Wake-on-LAN Sender ---\n";
    std::cout << "Enter target PC's MAC address (e.g., AA-BB-CC-DD-EE-FF): ";
    std::getline(std::cin, mac);

    std::cout << "Enter network broadcast address (e.g., 192.168.1.255): ";
    std::getline(std::cin, broadcast);

    sendMagicPacket(mac, broadcast);

    std::cout << "Press Enter to exit...";
    std::cin.get();

    return 0;
}
