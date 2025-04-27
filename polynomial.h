#ifndef POLYNOMIAL_H
#define POLYNOMIAL_H

#include <map>
#include <vector>
#include <string>
#include <iostream>
#include <cmath>

// (x^2y^1 -> {'x': 2, 'y': 1})
using Monom = std::map<char, int>;

using PolynomialData = std::map<Monom, double>;

class Polynomial {
public:
    PolynomialData terms;

    Polynomial();
    Polynomial(double constant);
    Polynomial(char variable);

    Polynomial(const Polynomial& other);

    Polynomial& operator=(const Polynomial& other);

    Polynomial operator+(const Polynomial& other) const;
    Polynomial operator-(const Polynomial& other) const;
    Polynomial operator-() const;
    Polynomial operator*(const Polynomial& other) const;
    Polynomial power(int exponent) const;

    static Polynomial fromConstant(double val) { return Polynomial(val); }
    static Polynomial fromVariable(char var) { return Polynomial(var); }

    std::string toString() const;
    friend std::ostream& operator<<(std::ostream& os, const Polynomial& p);

private:
    void cleanupZeros();

};

#endif // POLYNOMIAL_H