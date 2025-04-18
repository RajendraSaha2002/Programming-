#include <iostream>
using namespace std;

class Book {
private:
    string title;
    string author;

public:
    Book(string t, string a) : title(t), author(a) {}

    void display() {
        cout << "Title: " << title << "\nAuthor: " << author << endl;
    }
};

class Library {
private:
    Book* books[5];  // You can make it dynamic for a real-world app
    int count;

public:
    Library() : count(0) {}

    void addBook(Book* b) {
        if (count < 5) {
            books[count++] = b;
        } else {
            cout << "Library is full!" << endl;
        }
    }

    void showBooks() {
        for (int i = 0; i < count; i++) {
            books[i]->display();
            cout << "---" << endl;
        }
    }
};

int main() {
    Library lib;
    lib.addBook(new Book("Love Angle", "Rajendra Saha"));
    lib.addBook(new Book("Cyber Security", "Gautam Kumnauath"));
    lib.showBooks();
    return 0;
}
