#define _USE_MATH_DEFINES
#include <math.h>

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>

#include <iostream>
#include <vector>
#include <string>

cv::Mat get_lower_half(cv::Mat src) {
    int w = src.size().width;
    int h = src.size().height;

    cv::Mat res(src, cv::Rect(w*15/100, h*6/10, w*7/10, h*4/10));
    return res;
}

int main(int argc, char* argv[])
{
    if (argc < 2) {
        std::cout << "usage: " << argv[0] << " image" << std::endl;
        return 0;
    }

    cv::Mat original = cv::imread(argv[1], CV_LOAD_IMAGE_COLOR);
    if (original.empty()) {
        std::cerr << "Failed to open image file." << std::endl;
        return -1;
    }
    cv::Mat resized_img;

    // 下半分を取得
    cv::Mat lower_img = get_lower_half(original);

    // 解像度を1/4に
    resize(lower_img, resized_img, cv::Size(), 0.5, 0.5);

    imwrite("output.jpg", resized_img);

    return 0;
}
