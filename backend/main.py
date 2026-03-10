# -*- coding: utf-8 -*-
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
import shutil
import os
import uuid
import pandas as pd
from algorithm import ImageEnhancer

app = FastAPI(title="Flutter Image Processing API")

BASE_WORKSPACE = "temp_workspace"
os.makedirs(BASE_WORKSPACE, exist_ok=True)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "message": "Backend service is running"}

@app.post("/process_images/")
async def process_images(files: list[UploadFile] = File(...)):
    """Process uploaded images and return analysis results"""
    session_id = str(uuid.uuid4())
    current_folder = os.path.join(BASE_WORKSPACE, session_id)
    os.makedirs(current_folder, exist_ok=True)

    try:
        # Save uploaded files
        for file in files:
            file_path = os.path.join(current_folder, file.filename)
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

        # Process images using algorithm
        print(f"Processing request {session_id} with {len(files)} images...")
        enhancer = ImageEnhancer(current_folder)
        enhancer.process_all_images()

        # Read results from Excel
        result_dir = os.path.join(current_folder, 'enhanced_results')
        excel_path = os.path.join(result_dir, 'fluorescence_intensity_report.xlsx')

        if not os.path.exists(excel_path):
            return JSONResponse(
                status_code=500, 
                content={"error": "Failed to generate Excel file"}
            )

        # Convert Excel to JSON - Parse Chinese column names
        df = pd.read_excel(excel_path)
        df = df.where(pd.notnull(df), None)
        
        # Group by image filename (从时间列提取，因为时间列就是文件名去掉扩展名)
        results = []
        for time_point in df['时间'].unique():
            time_data = df[df['时间'] == time_point]
            
            # Get all 4 tubes' intensities for this image
            tubes = []
            for _, row in time_data.iterrows():
                tubes.append({
                    "tube_number": int(row['试管编号']),
                    "intensity": float(row['绝对荧光强度']),
                    "relative_intensity": float(row['相对荧光强度']) if row['相对荧光强度'] else 0,
                    "normalized_intensity": float(row['归一化荧光强度']) if row['归一化荧光强度'] else 0
                })
            
            # 时间列存储的是文件名（去掉扩展名），添加回扩展名
            image_filename = f"{time_point}.jpg" if not time_point.endswith('.jpg') else time_point
            
            results.append({
                "image_path": image_filename,
                "tubes": tubes,
                "average_intensity": sum(t['intensity'] for t in tubes) / len(tubes) if tubes else 0
            })

        return {
            "status": "success",
            "message": "Image processing completed",
            "session_id": session_id,
            "results": results
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return JSONResponse(
            status_code=500, 
            content={"error": f"Processing error: {str(e)}"}
        )

if __name__ == "__main__":
    import uvicorn
    print("=" * 50)
    print("Backend service starting...")
    print("Service URL: http://127.0.0.1:8000")
    print("API Docs: http://127.0.0.1:8000/docs")
    print("=" * 50)
    uvicorn.run(app, host="0.0.0.0", port=8000)
