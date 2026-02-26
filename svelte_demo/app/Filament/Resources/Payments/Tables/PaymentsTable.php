<?php

namespace App\Filament\Resources\Payments\Tables;

use App\Models\Payment;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class PaymentsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('order.id')
                    ->label('Order #')
                    ->sortable()
                    ->searchable()
                    ->prefix('#')
                    ->weight('bold')
                    ->color('primary'),

                TextColumn::make('order.user.name')
                    ->label('Customer')
                    ->searchable()
                    ->icon('heroicon-m-user-circle'),

                TextColumn::make('method')
                    ->label('Method')
                    ->badge()
                    ->icon(fn (string $state): string => match (strtolower($state)) {
                        'aba'     => 'heroicon-m-building-library',
                        'aceleda' => 'heroicon-m-credit-card',
                        default   => 'heroicon-m-banknotes',
                    })
                    ->color(fn (string $state): string => match (strtolower($state)) {
                        'aba'     => 'info',
                        'aceleda' => 'warning',
                        default   => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => strtoupper($state)),

                TextColumn::make('txn_id')
                    ->label('Transaction ID')
                    ->searchable()
                    ->copyable()
                    ->copyMessage('Transaction ID copied')
                    ->placeholder('—')
                    ->fontFamily('mono')
                    ->color('gray'),

                TextColumn::make('amount')
                    ->label('Amount')
                    ->money('IDR')
                    ->sortable()
                    ->weight('bold')
                    ->color('success'),

                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->icon(fn (string $state): string => match (strtolower($state)) {
                        'paid', 'completed', 'success' => 'heroicon-m-check-circle',
                        'failed', 'cancelled'          => 'heroicon-m-x-circle',
                        default                        => 'heroicon-m-clock',
                    })
                    ->color(fn (string $state): string => match (strtolower($state)) {
                        'paid', 'completed', 'success' => 'success',
                        'failed', 'cancelled'          => 'danger',
                        default                        => 'warning',
                    })
                    ->formatStateUsing(fn (string $state): string => ucfirst($state)),

                TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('M j, Y H:i')
                    ->sortable()
                    ->icon('heroicon-m-calendar'),
            ])
            ->defaultSort('created_at', 'desc')
            ->striped()
            ->filters([
                SelectFilter::make('status')
                    ->options([
                        'pending'   => 'Pending',
                        'paid'      => 'Paid',
                        'failed'    => 'Failed',
                        'cancelled' => 'Cancelled',
                    ]),
                SelectFilter::make('method')
                    ->options([
                        'aba'     => 'ABA',
                        'aceleda' => 'ACELEDA',
                    ]),
            ])
            ->recordActions([
                EditAction::make()
                    ->icon('heroicon-m-pencil-square')
                    ->visible(fn (Payment $record): bool => $record->status !== 'paid'),

                Action::make('viewPaid')
                    ->label('View')
                    ->icon('heroicon-o-eye')
                    ->color('gray')
                    ->visible(fn (Payment $record): bool => $record->status === 'paid')
                    ->url(fn (Payment $record): string => route('filament.admin.resources.payments.view', $record)),


                Action::make('payViaKhqr')
                    ->label('Pay via KHQR')
                    ->icon('heroicon-o-qr-code')
                    ->color('info')
                    ->visible(fn (Payment $record): bool => $record->status !== 'paid')
                    ->modalHeading('Scan to Pay')
                    ->modalContent(function (Payment $record, \App\Services\BakongService $bakongService): \Illuminate\Contracts\View\View {
                        // Generate QR and save MD5 to DB immediately
                        // This ensures the displayed QR matches the MD5 we poll in the API
                        $result = $bakongService->generateQR($record);

                        if ($result) {
                            $record->updateQuietly(['txn_id' => $result['md5']]);
                        }

                        $imageUrl = $result
                            ? $bakongService->getQrImageUrl($result['qr'])
                            : null;

                        return view('filament.modals.khqr', [
                            'imageUrl'  => $imageUrl,
                            'md5'       => $result['md5'] ?? null,
                            'amount'    => $record->amount,
                            'paymentId' => $record->id,
                        ]);
                    })
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('Close'),

                Action::make('checkKhqrPayment')
                    ->label('Check Payment')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->visible(fn (Payment $record): bool => ! empty($record->txn_id) && $record->status !== 'paid')
                    ->action(function (Payment $record, \App\Services\BakongService $bakongService): void {
                        if (! $record->txn_id) {
                            \Filament\Notifications\Notification::make()
                                ->title('No QR generated yet')
                                ->warning()
                                ->send();

                            return;
                        }

                        $isPaid = $bakongService->checkTransactionByMD5($record->txn_id);

                        if ($isPaid) {
                            $record->update(['status' => 'paid']);

                            \Filament\Notifications\Notification::make()
                                ->title('✅ Payment Confirmed!')
                                ->body('Status has been updated to Paid.')
                                ->success()
                                ->send();
                        } else {
                            \Filament\Notifications\Notification::make()
                                ->title('Payment not received yet')
                                ->body('Please ask the customer to complete the payment and try again.')
                                ->warning()
                                ->send();
                        }
                    }),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    // DeleteBulkAction::make()
                    //     ->action(function (\Illuminate\Support\Collection $records) {
                    //         // Only delete non-paid records
                    //         $records->filter(fn (Payment $record) => $record->status !== 'Paid')
                    //             ->each->delete();
                    //     }),
                ]),
            ]);
    }
}
