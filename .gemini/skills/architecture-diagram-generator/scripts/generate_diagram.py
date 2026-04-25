# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "google-genai",
#     "pillow",
# ]
# ///
import sys
import os
from io import BytesIO
from PIL import Image
from google import genai
from google.genai.types import GenerateContentConfig, Modality

def generate_diagram(prompt, output_file):
    enhanced_prompt = f"{prompt}. Style: highly professional, technical, enterprise architecture diagram, clear, modern, and suitable for official engineering documentation."
    client = genai.Client()
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=(enhanced_prompt,),
        config=GenerateContentConfig(
            response_modalities=[Modality.TEXT, Modality.IMAGE],
        ),
    )
    
    for part in response.candidates[0].content.parts:
        if part.inline_data:
            image = Image.open(BytesIO(part.inline_data.data))
            image.save(output_file)
            print(f"Generated diagram saved to {output_file}")
            return
            
    print("Failed to generate image.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python generate_diagram.py \"<prompt>\" <output_file>")
        sys.exit(1)
        
    prompt = sys.argv[1]
    output_file = sys.argv[2]
    generate_diagram(prompt, output_file)
