# 导入所需库
import cv2
import numpy as np
import os
import math
import pandas as pd
from tkinter import Tk, filedialog


class ImageEnhancer:
    def __init__(self, image_folder):
        self.image_folder = image_folder
        # 创建处理后图像目录
        self.result_dir = os.path.join(image_folder, 'enhanced_results')
        if not os.path.exists(self.result_dir):
            os.makedirs(self.result_dir)

        # 定义荧光中心区域范围
        self.fluorescence_regions = {
            1: (600, 800),  # 1号区域横坐标范围
            2: (1200, 1400),  # 2号区域横坐标范围
            3: (1700, 1900),  # 3号区域横坐标范围
            4: (2200, 2400)  # 4号区域横坐标范围
        }

        # 初始化计算区域字典
        self.calculation_regions = {}

    def process_image(self, image_path):
        """处理单张图像"""
        image = cv2.imread(image_path)
        if image is None:
            print(f"无法读取图像: {image_path}")
            return
        enhanced = self.enhance_image(image)
        image_name = os.path.basename(image_path)
        output_path = os.path.join(self.result_dir, f'enhanced_{image_name}')
        cv2.imwrite(output_path, enhanced)

    def extract_time_from_filename(self, filename):
        """从文件名中提取时间信息"""
        # 文件名格式：YYYYMMDD_HHMMSS.jpg
        time_str = filename.split('.')[0]  # 去掉扩展名
        return time_str

    def calculate_rotation_angle(self, point1, point2):
        """计算直线与水平线的夹角，并限制角度范围"""
        dx = point2[0] - point1[0]
        dy = point2[1] - point1[1]
        # 计算弧度
        angle_rad = math.atan2(dy, dx)
        # 转换为角度并取反
        angle_deg = -math.degrees(angle_rad)

        # 检查角度是否在3-6度范围内
        if 3 <= angle_deg <= 6:
            return angle_deg
        else:
            # 如果不在范围内，返回固定的4度角，
            return 4.0

    def enhance_image(self, image):
        # 保存原始图像用于后续恢复
        self.original_image = image.copy()

        # 预处理：降低图像曝光度
        adjusted_image = cv2.convertScaleAbs(image, alpha=2, beta=-20)  # alpha控制对比度，beta控制亮度

        # 转换到HSV颜色空间
        hsv = cv2.cvtColor(adjusted_image, cv2.COLOR_BGR2HSV)

        # 保存调整后的图像用于后续处理
        self.adjusted_image = adjusted_image.copy()

        # 定义白色的HSV范围 - 调整阈值使其更精确
        lower_white = np.array([0, 0, 180])  # 提高亮度阈值
        upper_white = np.array([255, 255, 255])

        # 创建白色区域的掩码
        white_mask = cv2.inRange(hsv, lower_white, upper_white)

        # 进行形态学操作以去除噪点
        kernel = np.ones((3, 3), np.uint8)
        white_mask = cv2.morphologyEx(white_mask, cv2.MORPH_OPEN, kernel)

        # 寻找轮廓
        contours, _ = cv2.findContours(white_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # 存储白点中心坐标
        white_points = []

        # 定义荧光中心区域范围
        fluorescence_regions = {
            1: (600, 800),  # 1号区域横坐标范围
            2: (1200, 1400),  # 2号区域横坐标范围
            3: (1700, 1900),  # 3号区域横坐标范围
            4: (2200, 2400)  # 4号区域横坐标范围
        }

        # 添加类变量来存储最后一次有效的白点位置
        if not hasattr(self, 'last_valid_white_points'):
            self.last_valid_white_points = None

        # 输出增强后的图像
        enhanced_image = self.adjusted_image.copy()
        cv2.imwrite(os.path.join(self.result_dir, 'enhanced_image.jpg'), enhanced_image)

        # 使用增强后的无框图像进行计算
        self.clean_image = enhanced_image.copy()

        # 在原图上标记白点
        result = image.copy()
        for contour in contours:
            # 计算轮廓面积
            area = cv2.contourArea(contour)
            # 过滤小面积噪点
            if area > 10:  # 可以调整这个阈值
                # 获取轮廓的中心点
                M = cv2.moments(contour)
                if M["m00"] != 0:
                    cx = int(M["m10"] / M["m00"])
                    cy = int(M["m01"] / M["m00"])
                    # 检查纵坐标是否在有效范围内（1700-2100像素）
                    if 1500 <= cy <= 2100:
                        # 检查横坐标是否在预期范围内
                        if 600 <= cx <= 2400:
                            white_points.append((cx, cy))

        # 添加一个类变量来存储所有能识别到两个及以上亮点的图片的参考点位置
        if not hasattr(self, 'all_valid_positions'):
            self.all_valid_positions = {1: [], 2: [], 3: [], 4: []}

        # 如果当前图片检测到有效的白点，计算并保存每个区域的平均位置
        if len(white_points) >= 2:
            region_averages = {}
            # 仅当检测到两个及以上白点时视为有效图片
            self.has_valid_image = True

            # 记录当前图片的有效区域位置
            for point in white_points:
                for region, (x_min, x_max) in self.fluorescence_regions.items():
                    if x_min <= point[0] <= x_max:
                        if region not in region_averages:
                            region_averages[region] = []
                        region_averages[region].append(point)

            # 存储当前图片的有效位置到累积列表
            for region, points in region_averages.items():
                if points:
                    self.all_valid_positions[region].extend(points)

            # 计算当前图片的区域平均位置
            self.last_valid_positions = {}
            for region, points in region_averages.items():
                if points:
                    avg_x = sum(p[0] for p in points) / len(points)
                    avg_y = sum(p[1] for p in points) / len(points)
                    self.last_valid_positions[region] = (int(avg_x), int(avg_y))

            self.last_valid_white_points = white_points

        # 当存在有效图片时，统一使用所有有效图片的平均位置
        if getattr(self, 'has_valid_image', False):
            avg_positions = {}
            # 计算所有有效图片各区域坐标的平均值
            for region in self.fluorescence_regions.keys():
                all_points = self.all_valid_positions.get(region, [])
                if len(all_points) > 0:
                    avg_x = sum(p[0] for p in all_points) / len(all_points)
                    avg_y = sum(p[1] for p in all_points) / len(all_points)
                    avg_positions[region] = (int(avg_x), int(avg_y))

            # 如果当前图片未检测到足够白点，应用全局平均位置
            if len(white_points) < 2 and avg_positions:
                self.last_valid_positions = avg_positions
                white_points = list(avg_positions.values())
                # 更新region_points以使用全局平均位置
                region_points = avg_positions.copy()
                detected_regions = set(avg_positions.keys())
        # 无任何有效图片时使用最后有效位置
        elif hasattr(self, 'last_valid_positions') and self.last_valid_positions:
            white_points = [point for point in self.last_valid_positions.values()]
        # 如果没有累积的有效位置但有上一次的有效位置，使用上一次的位置
        elif hasattr(self, 'last_valid_positions') and self.last_valid_positions:
            white_points = [point for point in self.last_valid_positions.values()]

        # 如果检测到两个或更多白点，计算旋转角度并保存参考点
        rotation_angle = 0
        if len(white_points) >= 2:
            # 按x坐标排序白点
            white_points.sort(key=lambda x: x[0])
            # 取最左和最右的点
            left_point = white_points[0]
            right_point = white_points[-1]

            # 计算旋转角度
            rotation_angle = self.calculate_rotation_angle(left_point, right_point)

            # 保存参考点和旋转角度
            height, width = result.shape[:2]
            center = (width // 2, height // 2)
            rotation_matrix = cv2.getRotationMatrix2D(center, rotation_angle, 1.0)

            # 计算旋转后的参考点位置
            left_point_arr = np.array([[left_point[0]], [left_point[1]], [1]])
            right_point_arr = np.array([[right_point[0]], [right_point[1]], [1]])
            rotated_left = np.dot(rotation_matrix, left_point_arr)
            rotated_right = np.dot(rotation_matrix, right_point_arr)

            self.last_valid_points = (
                (int(rotated_left[0][0]), int(rotated_left[1][0])),
                (int(rotated_right[0][0]), int(rotated_right[1][0])),
                rotation_angle
            )
        elif hasattr(self, 'last_valid_points'):
            # 如果当前图片没有检测到足够的白点，使用上一次的有效旋转角度
            _, _, rotation_angle = self.last_valid_points

        # 旋转图像使直线水平
        height, width = result.shape[:2]
        center = (width // 2, height // 2)
        rotation_matrix = cv2.getRotationMatrix2D(center, rotation_angle, 1.0)
        result = cv2.warpAffine(result, rotation_matrix, (width, height),
                                flags=cv2.INTER_LINEAR,
                                borderMode=cv2.BORDER_REPLICATE)

        # 保存旋转后的原始图像，用于计算荧光强度
        self.rotated_original = cv2.warpAffine(self.original_image.copy(), rotation_matrix, (width, height),
                                               flags=cv2.INTER_LINEAR,
                                               borderMode=cv2.BORDER_REPLICATE)

        # 在旋转后的图像上重新检测和标记白点
        rotated_hsv = cv2.cvtColor(result, cv2.COLOR_BGR2HSV)
        rotated_white_mask = cv2.inRange(rotated_hsv, lower_white, upper_white)
        rotated_white_mask = cv2.morphologyEx(rotated_white_mask, cv2.MORPH_OPEN, kernel)
        rotated_contours, _ = cv2.findContours(rotated_white_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        rotated_white_points = []
        detected_regions = set()

        # 存储所有检测到的蓝点的纵坐标
        blue_point_y_coordinates = []
        region_points = {}

        # 第一次遍历：收集所有检测到的点的信息，特别关注蓝点
        for contour in rotated_contours:
            area = cv2.contourArea(contour)
            if area > 10:
                M = cv2.moments(contour)
                if M["m00"] != 0:
                    cx = int(M["m10"] / M["m00"])
                    cy = int(M["m01"] / M["m00"])
                    if 1700 <= cy <= 2100:
                        for region, (x_min, x_max) in fluorescence_regions.items():
                            if x_min <= cx <= x_max:
                                # 添加位置累积逻辑
                                self.all_valid_positions[region].append((cx, cy))
                                detected_regions.add(region)
                                region_points[region] = (cx, cy)
                                if region in [2, 3]:
                                    blue_point_y_coordinates.append(cy)

        # 如果当前图片没有检测到蓝点，使用上一次有效的蓝点位置
        if not blue_point_y_coordinates and hasattr(self, 'last_valid_blue_points'):
            blue_point_y_coordinates = self.last_valid_blue_points
            # 恢复上一次的区域点信息
            for region, point in self.last_valid_region_points.items():
                if region in [2, 3]:  # 只恢复蓝点区域
                    region_points[region] = point
                    detected_regions.add(region)

        # 保存当前有效的蓝点信息
        if blue_point_y_coordinates:
            self.last_valid_blue_points = blue_point_y_coordinates
            self.last_valid_region_points = region_points.copy()

        # 计算蓝点的平均纵坐标
        target_y = int(np.mean(blue_point_y_coordinates)) if blue_point_y_coordinates else 1900

        # 第二次遍历：标记所有点
        for region in range(1, 5):
            if region in detected_regions:
                # 对于检测到的点，使用其实际位置或平均位置
                cx, cy = region_points[region]
                # 统一使用蓝点的纵坐标
                cy = target_y

                color = (255, 0, 0) if region in region_points else (0, 255, 0)
                cv2.circle(result, (cx, cy), 10, color, -1)
                cv2.putText(result, f'Region {region}',
                            (cx - 40, cy - 20),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8,
                            color, 2)

                # 绘制监测区域
                monitor_y = cy  # 标记点下方80像素
                rect_width = 300  # 统一设置框的宽度为250像素
                rect_height = 300  # 统一设置框的高度为60像素
                rect_x = cx - rect_width // 2
                rect_y = monitor_y - rect_height // 2
                top_left = (rect_x, rect_y)
                bottom_right = (rect_x + rect_width, rect_y + rect_height)
                cv2.rectangle(result, top_left, bottom_right, (255, 255, 255), 2)

                # 存储实际计算区域
                self.calculation_regions[region] = {
                    'x': rect_x, 'y': rect_y, 'width': rect_width, 'height': rect_height
                }
            else:
                # 对于未检测到的点，使用蓝点的纵坐标
                x_min, x_max = fluorescence_regions[region]
                center_x = (x_min + x_max) // 2
                # 使用蓝点的纵坐标
                cv2.circle(result, (center_x, target_y), 10, (0, 255, 0), -1)
                cv2.putText(result, f'Region {region}',
                            (center_x - 40, target_y - 20),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8,
                            (0, 255, 0), 2)

                monitor_y = target_y  # 调整偏移量，与其他区域保持一致
                rect_width = 300
                rect_height = 300
                rect_x = center_x - rect_width // 2
                rect_y = monitor_y - rect_height // 2
                top_left = (rect_x, rect_y)
                bottom_right = (rect_x + rect_width, rect_y + rect_height)
                cv2.rectangle(result, top_left, bottom_right, (255, 255, 255), 2)

                # 存储当前区域的计算区域
                self.calculation_regions[region] = {
                    'x': rect_x, 'y': rect_y, 'width': rect_width, 'height': rect_height
                }

        return result

    # =========================================================================
    # 核心修改：使用 Top 5% 亮度提取法，解决全黑框被平均稀释导致数值过小/为0的问题
    # =========================================================================
    def calculate_fluorescence_intensity(self, image, region_rect, region_num, image_name=None):
        """计算指定区域的荧光强度"""
        x, y, w, h = region_rect

        # 确保坐标在图像范围内
        height, width = image.shape[:2]
        x = max(0, min(x, width - 1))
        y = max(0, min(y, height - 1))
        w = min(w, width - x)
        h = min(h, height - y)

        # 直接使用完整的矩形区域
        roi = image[y:y + h, x:x + w]

        # 检查ROI是否有效
        if roi is None or roi.size == 0:
            print(f"警告：区域 {region_num} 的ROI无效 坐标: x={x}, y={y}, w={w}, h={h}")
            return 0

        # 转换为YUV颜色空间，并提取亮度通道
        yuv_roi = cv2.cvtColor(roi, cv2.COLOR_BGR2YUV)
        y_channel = yuv_roi[:, :, 0]

        # --- 新算法：只取框内最亮的 5% 的像素求平均 ---
        pixels = np.sort(y_channel.flatten())
        # 计算 5% 有多少个像素点 (对于 300x300 的框，就是最亮的 4500 个像素点)
        num_bright_pixels = int(len(pixels) * 0.05)

        if num_bright_pixels > 0:
            brightest_pixels = pixels[-num_bright_pixels:]
            intensity = np.mean(brightest_pixels)
        else:
            intensity = 0
        # ---------------------------------------------

        # 调试：打印区域的平均强度
        print(f"Region {region_num} at ({x}, {y}, {w}, {h}): 峰值荧光强度: {intensity:.2f}")

        # 保存ROI区域图像用于调试（保持你原有的功能）
        if image_name:
            roi_dir = os.path.join(self.result_dir, 'roi_images')
            if not os.path.exists(roi_dir):
                os.makedirs(roi_dir)
            roi_path = os.path.join(roi_dir, f'region{region_num}_{image_name}')
            cv2.imwrite(roi_path, roi)

            # 在原始图像上标记实际计算区域并保存
            debug_image = image.copy()
            cv2.rectangle(debug_image, (x, y), (x + w, y + h), (0, 0, 255), 2)
            cv2.putText(debug_image, f'区域 {region_num}',
                        (x, y - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8,
                        (0, 0, 255), 2)
            debug_path = os.path.join(roi_dir, f'debug_region{region_num}_{image_name}')
            cv2.imwrite(debug_path, debug_image)

        return intensity

    def process_all_images(self):
        """处理文件夹中的所有图像并生成Excel报告"""
        image_files = [f for f in os.listdir(self.image_folder) if f.endswith('.jpg')]
        image_files.sort()

        # 存储所有数据
        data = []
        initial_intensities = {1: None, 2: None, 3: None, 4: None}

        # 先反向处理图片以获取白点位置信息
        for image_file in reversed(image_files):
            image_path = os.path.join(self.image_folder, image_file)
            image = cv2.imread(image_path)
            if image is None: continue
            self.enhance_image(image)

        # 正向处理图片并保存结果
        for image_file in image_files:
            print(f"处理图像: {image_file}")
            image_path = os.path.join(self.image_folder, image_file)
            image = cv2.imread(image_path)
            if image is None: continue

            # 增强图像并获取处理后的结果
            enhanced = self.enhance_image(image)

            # 使用旋转后的原始图像进行计算
            base_for_calc = self.rotated_original

            # 创建一个调试图像，在上面显示所有区域
            debug_image = enhanced.copy()

            # 获取时间信息
            time_str = self.extract_time_from_filename(image_file)

            # 计算每个区域的荧光强度
            for region in range(1, 5):
                # 使用存储的计算区域，确保与显示的矩形完全一致
                if region in self.calculation_regions:
                    region_data = self.calculation_regions[region]
                    rect_x = region_data['x']
                    rect_y = region_data['y']
                    rect_width = region_data['width']
                    rect_height = region_data['height']
                else:
                    # (由于代码限制，简化这部分的备用方案，通常不会进这里)
                    rect_x, rect_y, rect_width, rect_height = 0, 0, 300, 300

                cv2.rectangle(debug_image, (rect_x, rect_y),
                              (rect_x + rect_width, rect_y + rect_height),
                              (0, 0, 255), 2)

                if enhanced is not None and region in self.calculation_regions:
                    intensity = self.calculate_fluorescence_intensity(
                        base_for_calc,
                        (rect_x, rect_y, rect_width, rect_height),
                        region,
                        image_file
                    )
                else:
                    intensity = 0

                if initial_intensities[region] is None:
                    initial_intensities[region] = intensity

                relative_intensity = intensity / initial_intensities[region] if initial_intensities[region] != 0 else 0
                normalized_intensity = (intensity - initial_intensities[region]) / initial_intensities[region] if \
                initial_intensities[region] != 0 else 0

                # 存储数据
                data.append({
                    '时间': time_str,
                    '试管编号': region,
                    '绝对荧光强度': intensity,
                    '相对荧光强度': relative_intensity,
                    '归一化荧光强度': normalized_intensity
                })

            output_path = os.path.join(self.result_dir, f'enhanced_{image_file}')
            cv2.imwrite(output_path, enhanced)
            debug_path = os.path.join(self.result_dir, f'debug_{image_file}')
            cv2.imwrite(debug_path, debug_image)

      
        df = pd.DataFrame(data)
        if not df.empty:
            # 1. 保存你原来的格式
            excel_path = os.path.join(self.result_dir, 'fluorescence_intensity_report.xlsx')
            df.to_excel(excel_path, index=False)

            # 2. 额外保存一份“宽格式”（列名为试管1、2、3、4），方便你直接在Excel里插图
            pivot_df = df.pivot(index='时间', columns='试管编号', values='绝对荧光强度')
            wide_excel_path = os.path.join(self.result_dir, 'fluorescence_report_chart_ready.xlsx')
            pivot_df.to_excel(wide_excel_path)

            print(f"\n所有图像处理完成！")
            print(f"数据已生成在文件夹: {self.result_dir}")
            print(f"-> 提示：如果想看折线图趋势，请打开 [fluorescence_report_chart_ready.xlsx]")
        else:
            print("未能生成有效数据。")


# =========================================================================
# 核心修改：使用弹窗代替手动改代码路径
# =========================================================================
# def main():
#     root = Tk()
#     root.withdraw()
#     folder_path = filedialog.askdirectory(title="请选择包含实验图像的文件夹")
#     root.destroy()
#
#     if folder_path:
#         print(f"正在处理文件夹: {folder_path} ...请稍候...")
#         enhancer = ImageEnhancer(folder_path)
#         enhancer.process_all_images()
#     else:
#         print("未选择文件夹，程序已退出。")
#
#
# if __name__ == "__main__":
#     main()
