{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 7,
   "id": "e5f41be4-30b0-4732-a1a7-922be69408b3",
   "metadata": {},
   "outputs": [
    {
     "ename": "ImportError",
     "evalue": "cannot import name 'TfidVectorizer' from 'sklearn.feature_extraction.text' (C:\\Users\\Rajendra Saha\\AppData\\Local\\Programs\\Python\\Python312\\Lib\\site-packages\\sklearn\\feature_extraction\\text.py)",
     "output_type": "error",
     "traceback": [
      "\u001b[1;31m---------------------------------------------------------------------------\u001b[0m",
      "\u001b[1;31mImportError\u001b[0m                               Traceback (most recent call last)",
      "Cell \u001b[1;32mIn[7], line 2\u001b[0m\n\u001b[0;32m      1\u001b[0m \u001b[38;5;28;01mimport\u001b[39;00m \u001b[38;5;21;01mrandom\u001b[39;00m\n\u001b[1;32m----> 2\u001b[0m \u001b[38;5;28;01mfrom\u001b[39;00m \u001b[38;5;21;01msklearn\u001b[39;00m\u001b[38;5;21;01m.\u001b[39;00m\u001b[38;5;21;01mfeature_extraction\u001b[39;00m\u001b[38;5;21;01m.\u001b[39;00m\u001b[38;5;21;01mtext\u001b[39;00m \u001b[38;5;28;01mimport\u001b[39;00m TfidVectorizer\n\u001b[0;32m      3\u001b[0m \u001b[38;5;28;01mfrom\u001b[39;00m \u001b[38;5;21;01msklearn\u001b[39;00m\u001b[38;5;21;01m.\u001b[39;00m\u001b[38;5;21;01mmetrics\u001b[39;00m\u001b[38;5;21;01m.\u001b[39;00m\u001b[38;5;21;01mpairwise\u001b[39;00m \u001b[38;5;28;01mimport\u001b[39;00m cosine_similarity\n\u001b[0;32m      4\u001b[0m \u001b[38;5;28;01mimport\u001b[39;00m \u001b[38;5;21;01mnltk\u001b[39;00m\n",
      "\u001b[1;31mImportError\u001b[0m: cannot import name 'TfidVectorizer' from 'sklearn.feature_extraction.text' (C:\\Users\\Rajendra Saha\\AppData\\Local\\Programs\\Python\\Python312\\Lib\\site-packages\\sklearn\\feature_extraction\\text.py)"
     ]
    }
   ],
   "source": [
    "import random\n",
    "from sklearn.feature_extraction.text import TfidVectorizer\n",
    "from sklearn.metrics.pairwise import cosine_similarity\n",
    "import nltk\n",
    "from nltk.corpus import wordnet as wn\n",
    "nltk.download('punkt')\n",
    "nltk.download('wordnet')\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 9,
   "id": "0b88eef8-7fc1-49b6-9ada-e36efefecc04",
   "metadata": {},
   "outputs": [],
   "source": [
    "class Chatbot:\n",
    "    def _init_(self, responses):\n",
    "        self.responses = responses\n",
    "        self.tfidf_vectorizer = TfidVectorizer(tokenizer=self.tokenize, stop_words='english')"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "id": "4e58d391-2485-4945-a0f1-87a43f0e8043",
   "metadata": {},
   "outputs": [],
   "source": [
    "def tokenize(text):\n",
    "    \"\"\"Tokenize and preprocess input text.\"\"\"\n",
    "    return nltk.word_tokenize(text.lower())\n",
    "    "
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 11,
   "id": "793b55b7-7098-4de2-b6eb-90344321ef6f",
   "metadata": {},
   "outputs": [],
   "source": [
    "def find_intent_match(self, user_input):\n",
    "    \"\"\"Match user input to the closest intent.\"\"\"\n",
    "    all_texts = list(self.responses.keys()) + [user_input]\n",
    "    tfidf_matrix = self.tfidf_vectorizer.fit_transform(all_texts)\n",
    "    cosine_vals = cosine_similarity(tfidf_matrix[-1], tfidf_matrix[:-1])\n",
    "    max_idx = cosine_vals.argmax()\n",
    "    return list(self.responses.keys())[max_idx], cosine_vals[0, max_idx]"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 12,
   "id": "b4bd8e18-6be4-470c-a8e9-66d04a2eccf6",
   "metadata": {},
   "outputs": [],
   "source": [
    "def get_response(self, user_input):\n",
    "    \"\"\"Generate a response based on user input.\"\"\"\n",
    "    intent, similarity = self.find_intent_match(user_input)\n",
    "    if similarity > 0.5:\n",
    "        return random.choice(self.responses[intent])\n",
    "    else:\n",
    "        return \"I'm sorry, I didn't understand that.\"\n",
    "        sample_responses = {\n",
    "        \"greeting\": [\"Hello!\", \"Hi there!\", \"Hey! How can I help?\"],\n",
    "        \"goodbye\": [\"Goodbye!\", \"See you later!\", \"Take care!\"],\n",
    "        \"thanks\": [\"You're welcome!\", \"No problem!\", \"Happy to help!\"],\n",
    "        \"default\": [\"I'm sorry, I didn't understand that.\"]\n",
    "        }"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 16,
   "id": "93b69364-57e9-4ddd-9e41-dc78a643e3db",
   "metadata": {},
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Chatbot initialized. Type 'quit' to exit.\n"
     ]
    },
    {
     "name": "stdin",
     "output_type": "stream",
     "text": [
      "You: hi\n",
      "You: quit\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Chatbot: Goodbye!\n"
     ]
    }
   ],
   "source": [
    "if __name__ == \"__main__\":\n",
    "\n",
    "    print(\"Chatbot initialized. Type 'quit' to exit.\")\n",
    "    while True:\n",
    "        user_message = input(\"You:\")\n",
    "        if user_message.lower() == 'quit':\n",
    "            print(\"Chatbot: Goodbye!\")\n",
    "            break\n",
    "            response = bot.get_response(user_message)\n",
    "            print(f\"Chatbot: {response}\")\n",
    "        "
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "01bcfa23-8eac-49f0-a410-762798b78400",
   "metadata": {},
   "outputs": [],
   "source": []
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3 (ipykernel)",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.8"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
