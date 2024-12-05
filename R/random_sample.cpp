#include <Rcpp.h>
#include <iostream>
#include <iterator>
#include <boost/random/uniform_01.hpp>
#include <boost/random/mersenne_twister.hpp>
#include <algorithm>

using namespace Rcpp;
using namespace boost::random;

// [[Rcpp::export]]
std::vector<size_t> random_sample(std::vector<double> w, int n) {

    // use Rcpp sugar to catch set.seed from R
    const auto seed = Rcpp::sample(std::numeric_limits<int>::max(), 1, false)[0];

    uniform_01<> dist;
    boost::random::mt19937 gen(seed);
    std::vector<double> vals;
    vals.reserve(w.size());

    for (auto iter : w)
    {
        vals.push_back(std::pow(dist(gen), 1. / iter));
    }
    // sorting vals, but retain the indices.
    // there is unfortunately no easy way to do this with STL.
    std::vector<std::pair<int, double>> valsWithIndices;
    valsWithIndices.reserve(vals.size());

    for (size_t iter = 0; iter < vals.size(); iter++)
    {
        valsWithIndices.emplace_back(iter, vals[iter]);
    }
    std::sort(valsWithIndices.begin(), valsWithIndices.end(), [](auto x, auto y) {return x.second > y.second;});

    std::vector<size_t> samples;
    samples.reserve(n);
    for (auto iter = 0; iter < n; iter++)
    {
        samples.push_back(valsWithIndices[iter].first + 1); // add 1 to correct for R indices
    }

    return samples;
}

