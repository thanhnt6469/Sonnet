# OpenAI API Setup Guide

## Overview
The Sonnet app uses OpenAI's API to generate music playlist recommendations based on your mood and selected genres. This guide will help you set up the API and handle common issues.

## Setup Instructions

### 1. Get an OpenAI API Key
1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign up or log in to your OpenAI account
3. Click "Create new secret key"
4. Copy the generated API key (it starts with `sk-`)

### 2. Configure the API Key
1. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Open the `.env` file and replace `your_openai_api_key_here` with your actual API key:
   ```
   token=sk-your-actual-api-key-here
   ```

### 3. Test the Configuration
Run the app and try generating a playlist. If everything is configured correctly, you should see playlist recommendations.

## Common Issues and Solutions

### 1. "OpenAI API quota exceeded" Error
**Problem**: You've reached your OpenAI API usage limit.

**Solutions**:
- **Check your billing**: Go to [OpenAI Billing](https://platform.openai.com/account/billing) to check your current usage and limits
- **Upgrade your plan**: If you're on a free tier, consider upgrading to a paid plan
- **Wait for reset**: Free tier quotas reset monthly
- **Use a different API key**: If you have multiple accounts

### 2. "Invalid API key" Error
**Problem**: The API key is incorrect or malformed.

**Solutions**:
- Verify the API key starts with `sk-`
- Check that there are no extra spaces or characters
- Ensure the key is copied correctly from OpenAI platform
- Generate a new API key if needed

### 3. "Rate limit exceeded" Error
**Problem**: Too many requests in a short time period.

**Solutions**:
- Wait a few minutes before trying again
- Reduce the frequency of requests
- Check your rate limits in the OpenAI dashboard

### 4. "Network error" Error
**Problem**: Internet connection issues.

**Solutions**:
- Check your internet connection
- Try again when connection is stable
- Check if OpenAI services are down

### 5. "API not configured" Error
**Problem**: The `.env` file is missing or incorrectly configured.

**Solutions**:
- Ensure the `.env` file exists in the project root
- Verify the file contains: `token=your_api_key_here`
- Check that the API key is not empty

## Cost Management

### Free Tier Limits
- OpenAI offers a free tier with limited usage
- Monitor your usage at [OpenAI Usage](https://platform.openai.com/usage)
- Set up billing alerts to avoid unexpected charges

### Estimated Costs
- Each playlist generation typically costs ~$0.001-0.005
- Costs depend on the model used and response length
- Monitor usage in your OpenAI dashboard

## Security Best Practices

1. **Never commit your API key**: The `.env` file should be in `.gitignore`
2. **Use environment variables**: Keep API keys out of your code
3. **Rotate keys regularly**: Generate new keys periodically
4. **Monitor usage**: Check your OpenAI dashboard regularly

## Troubleshooting

### If the app still doesn't work:
1. Check the console logs for detailed error messages
2. Verify your API key is valid by testing it in the OpenAI playground
3. Ensure you have sufficient credits in your OpenAI account
4. Try generating a new API key

### Getting Help
- Check [OpenAI Documentation](https://platform.openai.com/docs)
- Visit [OpenAI Community](https://community.openai.com/)
- Review error codes at [OpenAI Error Codes](https://platform.openai.com/docs/guides/error-codes)

## Alternative Solutions

If you continue to have quota issues, consider:
1. Using a different AI service provider
2. Implementing a local music recommendation system
3. Using pre-generated playlists based on mood/genre combinations
4. Adding a fallback to static playlist recommendations 