# Rails Log Monitor - Discord Bot

A Ruby application that monitors Rails log files in real-time and sends alerts to Discord when error patterns are detected.

## 📋 Features

- **Real-Time Monitoring**: Continuously tracks the log file for new entries
- **Flood Protection**: Prevents alert spam by enforcing configurable intervals
- **Multiple Platforms**: Extensible architecture to support different notification channels (Discord, Slack, etc.)
- **Customizable Patterns**: Detects various types of Rails and library errors
- **Systemd Service**: Can be executed as a daemon on the system
- **Log Rotation Support**: Automatically detects when the log file is rotated

## 🚨 Monitored Errors

The application monitors the following error patterns:

- `ERROR` - Standard Rails errors
- `FATAL` - Critical errors
- `ActiveRecord::StatementInvalid` - SQL errors
- `ActiveRecord::ConnectionNotEstablished` - Database connection failed
- `ActiveRecord::ConnectionTimeoutError` - Database connection timeout
- `Internal Server Error` - Generic 500 error
- `ActiveRecord::RecordNotUnique` - Attempt to duplicate unique records
- `PG::Error` - PostgreSQL driver errors
- `Mysql2::Error` - MySQL driver errors
- `NoMethodError` - Error when calling method on nil
- `ROLLBACK` - Database transaction rollback
- `Mongoid::Errors::*` - MongoDB errors
- `Mongo::Error::*` - MongoDB connection errors

## 📁 Project Structure

```
.
├── bin/
│   └── notifier.sh              # Monitor executable script
├── config/
│   └── .env.example             # Configuration example
├── models/
│   ├── alert_context.rb         # Alert context with protection
│   └── alert_strategies/
│       └── discord.rb           # Discord integration
├── services/
│   └── rails-logger.service     # Systemd service
├── notification_manager.rb      # Main manager
└── README.md
```

## ⚙️ Requirements

- Ruby 3.0+
- Access to a Rails log file
- Discord Webhook URL/Token
- (Optional) Systemd for service installation

## 🔧 Installation

### 1. Clone or copy the project

```bash
git clone <repository-url>
cd bot_discord
```

### 2. Configure environment variables

Create a `.env.development` file in the `config/` folder:

```bash
cp config/.env.example config/.env.development
# Edit the file with your Discord webhook
```

### 3. Get Discord Webhook

1. Access your Discord server
2. Go to **Server Settings** → **Webhooks**
3. Click **New Webhook**
4. Configure the name and channel
5. Copy the **Webhook URL**
6. Paste it in `config/.env.development`

## 🚀 How to Run

### Manual Mode

```bash
ruby notification_manager.rb
```

### As a Systemd Service

#### 1. Copy the service file

```bash
sudo cp services/rails-logger.service /etc/systemd/system/
```

#### 2. Edit the service file

```bash
sudo nano /etc/systemd/system/rails-logger.service
```

Update the paths:
- `WorkingDirectory` - where the project is located
- `ExecStart` - path to Ruby and `notifier.sh`
- `EnvironmentFile` - path to `config/.env.development`
- `User` and `Group` - user that will run the service

#### 3. Reload and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl start rails-logger.service
sudo systemctl enable rails-logger.service  # To start on boot
```

#### 4. Check the status

```bash
sudo systemctl status rails-logger.service
sudo journalctl -u rails-logger.service -f  # View logs in real-time
```

## 📊 How It Works

1. **Initialization**: The monitor opens the log file from the end
2. **Reading**: Reads new lines as they are added
3. **Detection**: Checks each line against configured patterns
4. **Flood Protection**: Validates if the minimum interval between alerts has been reached
5. **Notification**: If approved, sends the alert to Discord
6. **Rotation**: Detects when the log is rotated and reopens the file

## 🔐 Important Configurations

### Minimum Interval Between Alerts

Default: **5 seconds**

Edit in:
- `models/alert_context.rb`: `DEFAULT_MIN_INTERVAL_SECONDS`
- `models/alert_strategies/discord.rb`: `MIN_INTERVAL_SECONDS`

### Character Limit

Default: **1800 characters**

Edit in `models/alert_strategies/discord.rb`: `CHAR_LIMIT`

### Log File Path

Default: `/home/arthur/Desktop/list/log/development.log`

Edit in `notification_manager.rb`: `log_file_path`

## 🧪 Usage Example

```ruby
# Use directly in a Rails application
require_relative 'notification_manager'

# The monitor starts automatically
# Check Discord for incoming alerts
```

## 📝 Adding New Patterns

Edit `notification_manager.rb` and add regex to the `KEYWORDS` array:

```ruby
KEYWORDS = [
  /YOUR_PATTERN/i,  # Your new pattern (case-insensitive)
  # ... other patterns
]
```

## 🔗 Adding New Platforms

1. Create a new file in `models/alert_strategies/`:

```ruby
module AlertStrategies
  class YourPlatform
    MIN_INTERVAL_SECONDS = 5

    def initialize(uri: nil)
      @uri = uri
    end

    def notify(message: nil)
      # Implement the notification
    end
  end
end
```

2. Add to the notifiers list in `notification_manager.rb`:

```ruby
NOTIFIERS = [
  {
    platform: 'YourPlatform',
    log_file_path: '/path/to/log',
    uri: ENV['PLATFORM_WEBHOOK_URL']
  }
]
```

## 🐛 Troubleshooting

### Invalid Webhook
- Verify that the URL is correct in `.env.development`
- Test with curl: `curl -X POST -H 'Content-type: application/json' --data '{"content":"test"}' <WEBHOOK_URL>`

### Permission Denied
```bash
chmod +x bin/notifier.sh
```

### Log File Not Found
- Verify the path in `NOTIFIERS`
- Make sure your Rails application is writing logs

### Service Won't Start
```bash
sudo journalctl -u rails-logger.service -n 50  # View last 50 lines
```


## 👤 Author

Developed for monitoring Rails applications
