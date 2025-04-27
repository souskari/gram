#include "polynomial.h"
#include <sstream>
#include <vector>
#include <algorithm>
#include <iomanip>
#include <cmath>

const double EPSILON = 1e-9;

// --- Вспомогательные функции ---

int totalDegree(const Monom& m) {
    int degree = 0;
    for (const auto& pair : m) {
        degree += pair.second;
    }
    return degree;
}

bool compareMonoms(const std::pair<Monom, double>& a, const std::pair<Monom, double>& b) {
    int degreeA = totalDegree(a.first);
    int degreeB = totalDegree(b.first);
    if (degreeA != degreeB) {
        return degreeA > degreeB; // Сначала термы с большей степенью
    }
    // Если степени равны, сравниваем лексикографически по переменным
    return a.first < b.first; 
}

// --- Конструкторы ---

Polynomial::Polynomial() {
}

Polynomial::Polynomial(double constant) {
    terms[Monom()] = constant; // Monom() - пустая карта, представляет константу
    
}

Polynomial::Polynomial(char variable) {
    Monom m;
    m[variable] = 1;
    terms[m] = 1.0;
}

Polynomial::Polynomial(const Polynomial& other) {
    terms = other.terms;
}

// --- Оператор присваивания ---
Polynomial& Polynomial::operator=(const Polynomial& other) {
    if (this == &other) {
        return *this;
    }
    terms = other.terms;
    return *this;
}

void Polynomial::cleanupZeros() {
     auto it = terms.begin();
     while (it != terms.end()) {
         if (std::fabs(it->second) < EPSILON) {
             it = terms.erase(it);
         } else {
             ++it;
         }
     }
}


// --- Операции ---

Polynomial Polynomial::operator+(const Polynomial& other) const {
    // std::cerr << "DEBUG: Polynomial::operator+\n";
    // std::cerr << "  this: " << this->toString() << "\n";
    // std::cerr << "  other: " << other.toString() << "\n";

    Polynomial result = *this; // Копируем текущий полином
    for (const auto& pair : other.terms) {

        //в чем прикол оптимизации:
        /*
        У нас есть пара {'x', 1} переменная и ее степень. мы можем искать в каждом полиноме по переменной ее коэффициент
        То есть, если в 1ом полиноме есть 2x, а во втором 3x, то по ключу x мы найдем значения 2 и 3 и сложим их получив 5x без
        лишних манипуляций
        */
        result.terms[pair.first] += pair.second;
    }
    result.cleanupZeros(); // Удаляем термы с нулевыми коэффициентами

    // std::cerr << "  Returning: " << result.toString() << "\n";
    return result;
}

Polynomial Polynomial::operator-(const Polynomial& other) const { // Бинарный минус
    // std::cerr << "DEBUG: Polynomial::operator- (binary)\n";
    // std::cerr << "  this: " << this->toString() << "\n";
    // std::cerr << "  other: " << other.toString() << "\n";

    Polynomial result = *this; // Копируем текущий полином
    for (const auto& pair : other.terms) {
        result.terms[pair.first] -= pair.second;
    }
    result.cleanupZeros(); // Удаляем термы с нулевыми коэффициентами

    // std::cerr << "  Returning: " << result.toString() << "\n";
    return result;
}

Polynomial Polynomial::operator-() const { // Унарный минус
    // std::cerr << "DEBUG: Polynomial::operator- (unary)\n";
    // std::cerr << "  this: " << this->toString() << "\n";

    Polynomial result;
    if (terms.empty()) {
        //  std::cerr << "  Returning (empty input): " << result.toString() << "\n";
         return result; // Для -0 = 0
    }

    for (const auto& pair : terms) {
        if (std::fabs(pair.second) > EPSILON) {
           result.terms[pair.first] = -pair.second;
        }
    }

    // std::cerr << "  Returning: " << result.toString() << "\n";
    return result;
}

Polynomial Polynomial::operator*(const Polynomial& other) const {
    // std::cerr << "DEBUG: Polynomial::operator*\n";
    // std::cerr << "  this: " << this->toString() << "\n";
    // std::cerr << "  other: " << other.toString() << "\n";

    Polynomial result;
    if (terms.empty() || other.terms.empty()) {
        // std::cerr << "  Returning (zero multiplication): " << result.toString() << "\n";
        return result; 
    }

    for (const auto& term1 : terms) {
        const Monom& m1 = term1.first;
        double c1 = term1.second;

        for (const auto& term2 : other.terms) {
            const Monom& m2 = term2.first;
            double c2 = term2.second;

            Monom new_monom = m1;
            double new_coeff = c1 * c2;

            for (const auto& var_exp_pair : m2) {
                new_monom[var_exp_pair.first] += var_exp_pair.second;
                if (new_monom[var_exp_pair.first] == 0) {
                    new_monom.erase(var_exp_pair.first);
                }
            }

             if (std::fabs(new_coeff) > EPSILON) {
                result.terms[new_monom] += new_coeff;
                // std::cerr << "    Intermediate add to result: term " << Polynomial::MonomToString(new_monom) // Нужна вспомогательная функция MonomToString
                //           << " with coeff " << result.terms[new_monom] << "\n";
                // ----------------------------------------------------------------------
             }
        }
    }
    result.cleanupZeros();

    // std::cerr << "  Returning: " << result.toString() << "\n";
    return result;
}

Polynomial Polynomial::power(int exponent) const {
    if (exponent < 0) {
        std::cerr << "[WARNING] Ты пытаешься возвести число в отрицательную степень… Но не надо. Не существует такого уравнения, Нео" << std::endl;
        return Polynomial(); 
    }
    if (exponent == 0) {
        return Polynomial(1.0);
    }
    if (exponent == 1) {
        return *this; // P^1 = P
    }

    Polynomial result(1.0);
    Polynomial base = *this;
    int exp = exponent;

    while (exp > 0) {
        if (exp % 2 == 1) { // Если степень нечетная
            result = result * base;
        }
        base = base * base; // Возводим базу в квадрат
        exp /= 2;          // Уменьшаем степень вдвое
    }
    return result;
}

// --- Вывод полинома ---

std::string Polynomial::toString() const {
    if (terms.empty()) {
        return "0";
    }

    std::vector<std::pair<Monom, double>> sorted_terms(terms.begin(), terms.end());

    std::sort(sorted_terms.begin(), sorted_terms.end(), compareMonoms);

    std::stringstream ss;
    bool first_term = true;

    for (const auto& pair : sorted_terms) {
        const Monom& monom = pair.first;
        double coeff = pair.second;

        if (std::fabs(coeff) < EPSILON) {
            continue;
        }

        double abs_coeff = std::fabs(coeff);
        bool is_negative = coeff < 0.0;

        if (!first_term) {
            ss << (is_negative ? " - " : " + ");
        } else if (is_negative) {
            ss << "-";
        }

        bool monom_is_constant = monom.empty();
        bool coeff_is_one = std::fabs(abs_coeff - 1.0) < EPSILON;

        if (!coeff_is_one || monom_is_constant) {
             ss << abs_coeff;
        }

        if (!monom_is_constant) {
            if (coeff_is_one && first_term && !is_negative && monom.empty()) {
                 ss << "1"; 
            }

             if (!coeff_is_one && !monom.empty() ) {
             }

            bool first_var = true;
            for (const auto& var_pair : monom) {
                char variable = var_pair.first;
                int exponent = var_pair.second;
                ss << variable;
                if (exponent > 1) {
                    ss << "^" << exponent;
                }
                first_var = false;
            }
        }

        first_term = false;
    }

    std::string result_str = ss.str();
    if (result_str.empty()) return "0";

    if (result_str.length() > 3 && result_str.substr(0, 3) == " - ") {
    }


    return result_str;
}


std::ostream& operator<<(std::ostream& os, const Polynomial& p) {
    os << p.toString();
    return os;
}