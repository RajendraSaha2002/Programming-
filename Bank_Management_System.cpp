#include <iostream>
using namespace std;

class BankAccount {
private:
    string name;
    int accountNumber;
    float balance;

public:
    BankAccount(string accName, int accNumber, float initialBalance) {
        name = accName;
        accountNumber = accNumber;
        balance = initialBalance;
    }

    void deposit(float amount) {
        balance += amount;
    }

    void withdraw(float amount) {
        if (amount <= balance)
            balance -= amount;
        else
            cout << "Insufficient balance!" << endl;
    }

    void display() {
        cout << "Name: " << name << "\nAccount Number: " << accountNumber << "\nBalance: $" << balance << endl;
    }
};

int main() {
    BankAccount acc1("Rajendra Saha", 12345, 500.0f);
    acc1.deposit(200.0f);
    acc1.withdraw(100.0f);
    acc1.display();
    return 0;
}
