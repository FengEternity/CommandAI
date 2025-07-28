from openai import OpenAI
 
client = OpenAI(
    api_key = "sk-sfaBCLrIZ3PZOuY05EJ1V3P3gw5LFNUPfTVET1K3sPFl7lXr",
    base_url = "https://api.moonshot.cn/v1",
)
 
model_list = client.models.list()
model_data = model_list.data
 
for i, model in enumerate(model_data):
    print(f"model[{i}]:", model.id)